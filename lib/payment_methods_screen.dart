import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'package:twinmart_app/e_receipt_screen.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class PaymentMethodsScreen extends StatefulWidget {
  final double amount;
  final List<Map<String, dynamic>> items;
  final bool isOnlineOrder;

  const PaymentMethodsScreen({
    super.key, 
    required this.amount, 
    required this.items,
    this.isOnlineOrder = false,
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  int _selectedMethodIndex = -1;
  bool _isLoading = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("✅ Razorpay SUCCESS: ${response.paymentId}");
    _executeFirebaseTransaction("TXN-${DateTime.now().millisecondsSinceEpoch}");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("🔥 Razorpay ERROR: ${response.code} - ${response.message}");
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Cancelled or Failed."), backgroundColor: Colors.red),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("🏦 External Wallet: ${response.walletName}");
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedMethodIndex == 3 || _selectedMethodIndex == -1) {
      // Cash on Delivery
      _executeFirebaseTransaction("TXN-${DateTime.now().millisecondsSinceEpoch}");
    } else if (kIsWeb) {
      // ✅ WEB FIX: Use JS Bridge to avoid MissingPluginException
      try {
        debugPrint("🌐 Using Web JS Bridge for Razorpay...");
        var options = {
          'key': 'rzp_live_SRNY9I1iXz4BCU',
          'amount': (widget.amount * 100).toInt(),
          'name': 'TwinMart',
          'description': 'Store Purchase',
          'prefill': {
            'contact': '9876543210',
            'email': user.email ?? 'dummy@twinmart.com'
          },
          'capture': 1, // ✅ ADDED: Auto-capture payment immediately
          'handler': js.allowInterop((response) {
            // Convert JS response back to Dart
            _handlePaymentSuccess(PaymentSuccessResponse(
              response['razorpay_payment_id'],
              response['razorpay_order_id'],
              response['razorpay_signature'],
              {}, // Add 4th argument: data
            ));
          }),
          'modal': {
            'ondismiss': js.allowInterop(() {
              debugPrint("🚪 Razorpay Modal Dismissed");
              if (mounted) setState(() => _isLoading = false);
            }),
            'onerror': js.allowInterop((err) {
              debugPrint("🔥 Razorpay Modal Error: $err");
              if (mounted) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Payment Modal Error: $err"), backgroundColor: Colors.red),
                );
              }
            }),
          }
        };

        var rzp = js.JsObject(js.context['Razorpay'], [js.JsObject.jsify(options)]);
        rzp.callMethod('open');
      } catch (e) {
        debugPrint("🔥 Web Payment Error: $e");
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Razorpay Checkout (Mobile/Desktop)
      var options = {
        'key': 'rzp_live_SRNY9I1iXz4BCU', 
        'amount': (widget.amount * 100).toInt(),
        'name': 'TwinMart',
        'description': 'Store Purchase',
        'prefill': {
          'contact': '9876543210',
          'email': user.email ?? 'dummy@twinmart.com'
        },
        'capture': 1, // ✅ ADDED: Auto-capture payment immediately
      };
      
      try {
        debugPrint("💎 Opening Razorpay Checkout...");
        _razorpay.open(options);
        
        // Safety Reset
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _isLoading) {
            setState(() => _isLoading = false);
            debugPrint("⏳ Razorpay Timeout: Stopped buffering.");
          }
        });
      } catch (e) {
        debugPrint('🔥 Error starting Razorpay: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open Razorpay: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _executeFirebaseTransaction(String transactionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final budgetRef = userRef.collection('budget').doc('settings');

    try {
      
      debugPrint("🚀 Starting Payment Transaction: $transactionId");
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Fetch budget and product snapshots first (Reads)
        DocumentSnapshot budgetSnapshot = await transaction.get(budgetRef);
        
        Map<String, DocumentSnapshot> productSnaps = {};
        for (var item in widget.items) {
          if (item['id'] != null && !productSnaps.containsKey(item['id'])) {
            final pRef = FirebaseFirestore.instance.collection('products').doc(item['id']);
            productSnaps[item['id']] = await transaction.get(pRef);
          }
        }

        // 2. Perform Writes
        final orderRef = FirebaseFirestore.instance.collection('orders').doc(transactionId);
        transaction.set(orderRef, {
          'userId': user.uid,
          'totalAmount': widget.amount,
          'itemsCount': widget.items.length,
          'timestamp': FieldValue.serverTimestamp(),
          'paymentMethod': _getPaymentMethodName(_selectedMethodIndex),
          'status': 'Completed',
          'type': widget.isOnlineOrder ? 'online' : 'offline',
        });

        for (var item in widget.items) {
          // A. Create User Transaction Record
          final transRef = userRef.collection('transactions').doc();
          transaction.set(transRef, {
            'transactionId': transactionId,
            'productId': item['id'],
            'productName': item['name'],
            'productImage': item['imageUrl'] ?? item['image'],
            'price': item['price'],
            'quantity': item['quantity'] ?? 1,
            'category': item['category'] ?? 'Miscellaneous',
            'timestamp': FieldValue.serverTimestamp(),
            'paymentMethod': _getPaymentMethodName(_selectedMethodIndex),
            'type': widget.isOnlineOrder ? 'online' : 'offline',
          });

          // B. Decrement Product Stock (Simplified to single 'stock' field)
          final snap = productSnaps[item['id']];
          if (snap != null && snap.exists) {
            final data = snap.data() as Map<String, dynamic>;
            final int currentStock = (data['stock'] ?? 0);
            final int buyQty = (item['quantity'] ?? 1);
            transaction.update(snap.reference, {'stock': currentStock - buyQty});
            
            // Also sync other fields if they exist to prevent confusion
            if (data.containsKey('onlineStock')) transaction.update(snap.reference, {'onlineStock': currentStock - buyQty});
            if (data.containsKey('offlineStock')) transaction.update(snap.reference, {'offlineStock': currentStock - buyQty});
          }
        }
        
        if (budgetSnapshot.exists) {
          // Build a map of category -> total spend for this session
          Map<String, double> categoryTotals = {};
          for (var item in widget.items) {
            String category = (item['category'] ?? 'Miscellaneous').toString();
            double itemTotal = (item['price'] ?? 0.0).toDouble() * ((item['quantity'] ?? 1) as num).toDouble();
            categoryTotals[category] = (categoryTotals[category] ?? 0.0) + itemTotal;
          }

          // Read current spending for each affected category and accumulate
          Map<String, dynamic> updates = {};
          for (var entry in categoryTotals.entries) {
            double currentSpend = 0.0;
            try {
              currentSpend = (budgetSnapshot.get('category_spending.${entry.key}') ?? 0.0).toDouble();
            } catch (_) {}
            updates['category_spending.${entry.key}'] = currentSpend + entry.value;
          }

          if (updates.isNotEmpty) {
            transaction.update(budgetRef, updates);
          }
        }
      });
      debugPrint("✅ Transaction Complete");

      // Send automatic email receipt in the background
      _sendEmailReceipt(transactionId);

      // Show the feedback popup (SnackBar) that the user requested
      if (mounted) {
        final String userEmail = user.email ?? "your email";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text("Sending e-receipt to $userEmail...")),
              ],
            ),
            backgroundColor: const Color(0xFF1DB98A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      if (!mounted) return;
      // Show QR exit pass only for in-store barcode purchases.
      // Online/shop orders just show a simple success confirmation.
      if (widget.isOnlineOrder) {
        _showOrderSuccessDialog(transactionId);
      } else {
        _showExitQrDialog(transactionId);
      }
    } catch (e, stack) {
      debugPrint("🔥 Payment Error: $e");
      debugPrint("🔥 Stack: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment Failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Function to trigger automatic server-side email receipt via Firebase
  // ✅ Function to trigger automatic background email receipt via EmailJS (FREE Tier)
  Future<void> _sendEmailReceipt(String txnId) async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;
    if (userEmail == null) return;

    // Fetch original username from Firestore (Signup uses 'name' key)
    String userName = user?.displayName ?? 'Customer';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists && userDoc.data() != null && userDoc.data()!.containsKey('name')) {
        userName = userDoc.data()!['name'];
        if (userName.trim().isEmpty) userName = 'Customer';
      }
    } catch (e) {
      debugPrint("🔥 Error fetching genuine user name: $e");
    }

    // --- SETUP YOUR EMAILJS KEYS HERE ---
    const String serviceId = 'service_fvcp87z';  // Paste the Service ID you just got
    const String templateId = 'template_g3jov3v'; // We will get this next
    const String publicKey = 'Qn6OHFJGf6WRBiIir'; // We will get this next

    // Format product names for the email receipt
    final String productNames = widget.items
        .map((item) => "${item['name']} (x${item['quantity'] ?? 1})")
        .join(", ");

    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': userEmail,
            'user_name': userName, // Sending the genuine name!
            'order_id': txnId,
            'total_amount': widget.amount.toString(),
            'items_count': widget.items.length.toString(),
            'product_names': productNames, // Sending product names to EmailJS
            'payment_method': _getPaymentMethodName(_selectedMethodIndex),
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("📧 EmailJS receipt sent successfully to $userEmail");
      } else {
        debugPrint("🔥 EmailJS Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("🔥 Error sending EmailJS receipt: $e");
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  String _getPaymentMethodName(int index) {
    switch (index) {
      case 0: return "Debit Card (**** 4582)";
      case 1: return "UPI (shinto@okaxis)";
      case 2: return "Net Banking";
      case 3: return "Cash on Delivery";
      default: return "Unknown";
    }
  }

  void _showExitQrDialog(String txnId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 10),
            Text("Payment Successful", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Please show this QR code at the exit gate to leave.", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            const SizedBox(height: 20),
            Container(
              height: 220,
              width: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white, // QR must be on white
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: QrImageView(
                data: "EXIT_PASS|$txnId|${widget.amount.toInt()}|${widget.items.length}",
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                errorStateBuilder: (cxt, err) {
                  return const Center(
                    child: Text(
                      "QR Error",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text("Txn: $txnId", style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB98A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to scan screen
            },
            child: const Text("Done & Exit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showOrderSuccessDialog(String txnId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 44),
            ),
            const SizedBox(height: 18),
            Text(
              "Order Placed! 🎉",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Your order has been confirmed.\nThank you for shopping with TwinMart!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              "Order ID: $txnId",
              style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6) ?? Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB98A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(double.infinity, 48),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);       // Close dialog
                  Navigator.pop(context, true); // Return to shopping
                },
                child: const Text(
                  "Continue Shopping",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "E-receipt has been sent to your email",
              style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor.withOpacity(0.8), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = Color(0xFF1DB98A);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -100,
            left: -80,
            size: 280,
            color: TwinMartTheme.brandGreen.withOpacity(0.12),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Total Amount Header
                        _buildTotalAmountCard(context),
                        const SizedBox(height: 30),

                        // UPI Section
                        _buildSectionHeader("UPI"),
                        const SizedBox(height: 12),
                        _buildPaymentOption(
                          index: 1,
                          title: "Pay via UPI",
                          subtitle: "GPay, PhonePe, Paytm",
                          trailingContent: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/UPI-Logo-vector.svg/1200px-UPI-Logo-vector.svg.png',
                            height: 12,
                          ),
                          infoAlert: "You will need to accept the request in your UPI app.",
                        ),

                        const SizedBox(height: 25),

                        // Another Methods Section
                        _buildSectionHeader("Another payment method"),
                        const SizedBox(height: 12),
                        
                        _buildPaymentOption(
                          index: 0,
                          title: "Credit or debit card",
                          subtitle: "VISA, Mastercard, RuPay",
                          trailingContent: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _cardIcon('visa'),
                              const SizedBox(width: 4),
                              _cardIcon('mastercard'),
                              const SizedBox(width: 4),
                              _cardIcon('rupay'),
                            ],
                          ),
                        ),
                        
                        _buildPaymentOption(
                          index: 2,
                          title: "Net Banking",
                          subtitle: "Choose from 50+ banks",
                        ),

                        if (widget.isOnlineOrder)
                          _buildPaymentOption(
                            index: 3,
                            title: "Cash on Delivery",
                            subtitle: "Cash, UPI and Cards accepted.",
                            infoAlert: "Pay when you receive your order.",
                          ),
                        
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                _buildBottomAction(context, twinGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmountCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text("Payable Amount", 
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("₹", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: TwinMartTheme.brandGreen, height: 1.5)),
              Text("${widget.amount.toInt()}", 
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, letterSpacing: -1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required String title,
    required String subtitle,
    Widget? trailingContent,
    String? infoAlert,
  }) {
    bool isSelected = _selectedMethodIndex == index;
    const Color brandGreen = Color(0xFF1DB98A);

    return GestureDetector(
      onTap: () => setState(() => _selectedMethodIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? brandGreen.withOpacity(0.05) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? brandGreen : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? brandGreen : Colors.grey.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isSelected 
                      ? Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: brandGreen))
                      : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          if (trailingContent != null) ...[
                            const SizedBox(width: 8),
                            trailingContent,
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.withOpacity(0.3)),
              ],
            ),
            if (infoAlert != null && isSelected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: brandGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(infoAlert, style: const TextStyle(fontSize: 12, color: brandGreen, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cardIcon(String type) {
    String url = '';
    if (type == 'visa') url = 'https://img.icons8.com/color/48/visa.png';
    if (type == 'mastercard') url = 'https://img.icons8.com/color/48/mastercard.png';
    if (type == 'rupay') url = 'https://img.icons8.com/color/48/rupay.png';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Image.network(
        url, 
        height: 14, 
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(), // Hide if image fails
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, Color twinGreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isEnabled = _selectedMethodIndex != -1 && !_isLoading;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isEnabled ? _processPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: twinGreen,
              disabledBackgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
              elevation: isEnabled ? 4 : 0,
              shadowColor: twinGreen.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    "Use this payment method", 
                    style: TextStyle(
                      color: isEnabled ? Colors.white : (isDark ? Colors.white38 : Colors.grey[500]),
                      fontSize: 16, 
                      fontWeight: FontWeight.w800
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 10, right: 10, bottom: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 5),
          TwinMartTheme.brandLogo(size: 20, context: context),
          const SizedBox(width: 8),
          TwinMartTheme.brandText(fontSize: 22, context: context),
          const Spacer(),
          Text("Checkout",
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

}