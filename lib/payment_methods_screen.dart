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
    } else {
      // Razorpay Checkout
      var options = {
        'key': 'rzp_test_YourTestKey', // ❗ Replace with your test or live Razorpay key
        'amount': (widget.amount * 100).toInt(), // amount in paise
        'name': 'TwinMart',
        'description': 'Store Purchase',
        'prefill': {
          'contact': '9876543210', // You can dynamically get user phone if available
          'email': user.email ?? 'dummy@twinmart.com'
        }
      };
      
      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('🔥 Error starting Razorpay: $e');
        if (mounted) setState(() => _isLoading = false);
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
    const Color darkColor = Color(0xFF1C252E);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -100,
            left: -80,
            size: 280,
            color: TwinMartTheme.brandGreen.withOpacity(0.15),
          ),
          TwinMartTheme.bgBlob(
            bottom: 150,
            right: -100,
            size: 320,
            color: TwinMartTheme.brandBlue.withOpacity(0.1),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Payment Method",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        Text("Choose your preferred way to pay",
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: darkColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Text("Total Amount", style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 5),
                              Text("₹${widget.amount.toInt()}", 
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text("Payment Options", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        
                        _buildSelectableTile(0, "VISA Debit Card", "**** **** **** 4582", Icons.credit_card, twinGreen),
                        _buildSelectableTile(1, "UPI", "shinto@okaxis", Icons.account_balance_wallet, twinGreen),
                        _buildSelectableTile(2, "Net Banking", "HDFC Bank", Icons.account_balance, twinGreen),
                        if (widget.isOnlineOrder)
                          _buildSelectableTile(3, "Cash on Delivery", "Pay when you receive", Icons.payments_outlined, twinGreen),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _selectedMethodIndex != -1 && !_isLoading 
                            ? _processPayment 
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: twinGreen,
                          disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey[300],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text("Pay ₹${widget.amount.toInt()}", 
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildSelectableTile(int index, String title, String subtitle, IconData icon, Color activeColor) {
    bool isSelected = _selectedMethodIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMethodIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent, 
            width: 2
          ),
          boxShadow: [
            if (!isSelected) 
              BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withOpacity(0.1) : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100]),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isSelected ? activeColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey)),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7))),
          subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          trailing: isSelected 
              ? Icon(Icons.check_circle, color: activeColor)
              : const Icon(Icons.circle_outlined, color: Colors.grey),
        ),
      ),
    );
  }
}