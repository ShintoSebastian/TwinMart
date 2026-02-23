import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: TwinMartTheme.bgLight,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -120,
            left: -100,
            size: 320,
            color: TwinMartTheme.brandGreen.withOpacity(0.2),
          ),
          TwinMartTheme.bgBlob(
            bottom: -80,
            right: -100,
            size: 300,
            color: TwinMartTheme.brandBlue.withOpacity(0.15),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: userId.isEmpty
                      ? const Center(child: Text("Please login to view orders"))
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('orders')
                              .where('userId', isEqualTo: userId)
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: TwinMartTheme.brandGreen));
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Center(child: Text("No orders found."));
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                var order = snapshot.data!.docs[index];
                                return _buildOrderCard(order);
                              },
                            );
                          },
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
          const Text("Orders",
              style: TextStyle(
                  color: TwinMartTheme.darkText, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildOrderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text("Order #${doc.id.substring(0, 8)}", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total: ₹${data['totalAmount']}"),
            Text("Date: ${data['timestamp']?.toDate().toString().split(' ')[0]}"),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text("Delivered", style: TextStyle(color: Colors.green, fontSize: 12)),
        ),
      ),
    );
  }
}