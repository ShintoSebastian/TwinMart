import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;

class EReceiptScreen extends StatelessWidget {
  final String orderId;
  final double amount;
  final List<Map<String, dynamic>> items;
  final String paymentMethod;
  final DateTime timestamp;

  const EReceiptScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.items,
    required this.paymentMethod,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = Color(0xFF1DB98A);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("E-Receipt", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Logic to share receipt
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: () {
              // Logic to download as PDF
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -100,
            right: -80,
            size: 280,
            color: twinGreen.withOpacity(0.1),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                   _buildReceiptCard(context, twinGreen),
                   const SizedBox(height: 30),
                   _buildSupportSection(context, twinGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, Color green) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          // Receipt Header
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: green.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                TwinMartTheme.brandLogo(size: 40, context: context),
                const SizedBox(height: 15),
                TwinMartTheme.brandText(fontSize: 24, context: context),
                const SizedBox(height: 10),
                const Text("Payment Successful", 
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                Text("₹${amount.toStringAsFixed(2)}", 
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
              ],
            ),
          ),

          // Custom "Tear-off" Divider
          Row(
            children: List.generate(20, (index) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 1,
                color: Colors.grey.withOpacity(0.2),
              ),
            )),
          ),

          // Receipt Details
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow("Order ID", orderId, context),
                _detailRow("Date", DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp), context),
                _detailRow("Payment Method", paymentMethod, context),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(),
                ),
                Text("ORDER SUMMARY", 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey[500])),
                const SizedBox(height: 15),
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'] ?? "Item", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Qty: ${item['quantity'] ?? 1}", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                      ),
                      Text("₹${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}", 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )).toList(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Pay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("₹${amount.toStringAsFixed(2)}", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: green)),
                  ],
                ),
              ],
            ),
          ),

          // Barcode Decoration (Aesthetic)
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context, Color green) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline_rounded, color: green),
          const SizedBox(width: 15),
          const Expanded(
            child: Text("Have a question about this order? Contact our support 24/7.", 
              style: TextStyle(fontSize: 12)),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: green),
        ],
      ),
    );
  }
}
