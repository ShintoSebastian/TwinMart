import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;

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

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final budgetRef = userRef.collection('budget').doc('settings');

    try {
      String transactionId = "TXN-${DateTime.now().millisecondsSinceEpoch}";
      
      debugPrint("🚀 Starting Payment Transaction: $transactionId");
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(budgetRef);
        
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
          final transRef = userRef.collection('transactions').doc();
          transaction.set(transRef, {
            'transactionId': transactionId,
            'productName': item['name'],
            'price': item['price'],
            'quantity': item['quantity'] ?? 1,
            'category': item['category'] ?? 'General',
            'timestamp': FieldValue.serverTimestamp(),
            'paymentMethod': _getPaymentMethodName(_selectedMethodIndex),
            'type': widget.isOnlineOrder ? 'online' : 'offline',
          });
        }
        
        if (snapshot.exists) {
          double currentDigiSpending = 0.0;
          try {
             currentDigiSpending = (snapshot.get('category_spending.Digitals') ?? 0.0).toDouble();
          } catch (_) {}
          
          transaction.update(budgetRef, {
            'category_spending.Digitals': currentDigiSpending + widget.amount,
          });
        }
      });
      debugPrint("✅ Transaction Complete");

      if (!mounted) return;
      _showExitQrDialog(transactionId);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 10),
            Text("Payment Successful", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please show this QR code at the exit gate to leave.", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              height: 220,
              width: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
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
            Text("Txn: $txnId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = Color(0xFF1DB98A);
    const Color darkColor = Color(0xFF1C252E);

    return Scaffold(
      backgroundColor: TwinMartTheme.bgLight,
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
                        const Text("Choose your preferred way to pay",
                            style: TextStyle(color: Colors.grey)),
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
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
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
                          disabledBackgroundColor: Colors.grey[300],
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
            icon: const Icon(Icons.arrow_back, color: TwinMartTheme.darkText),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 5),
          TwinMartTheme.brandLogo(size: 20),
          const SizedBox(width: 8),
          TwinMartTheme.brandText(fontSize: 22),
          const Spacer(),
          const Text("Checkout",
              style: TextStyle(
                  color: TwinMartTheme.darkText, fontWeight: FontWeight.bold)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent, 
            width: 2
          ),
          boxShadow: [
            if (!isSelected) 
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withOpacity(0.1) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isSelected ? activeColor : Colors.grey),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey[800])),
          subtitle: Text(subtitle),
          trailing: isSelected 
              ? Icon(Icons.check_circle, color: activeColor)
              : const Icon(Icons.circle_outlined, color: Colors.grey),
        ),
      ),
    );
  }
}