import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_details_screen.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

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
                      ? const Center(child: Text("Please login to see your wishlist"))
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('wishlist')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: TwinMartTheme.brandGreen));
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Center(child: Text("Your wishlist is empty"));
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                var item = snapshot.data!.docs[index];
                                return _buildWishlistItem(
                                    context, item, userId, TwinMartTheme.brandGreen);
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
          const Text("Wishlist",
              style: TextStyle(
                  color: TwinMartTheme.darkText, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(BuildContext context, DocumentSnapshot doc, String userId, Color green) {
    final data = doc.data() as Map<String, dynamic>;
    final String? imageUrl = data['imageUrl'];

    return GestureDetector(
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
        
        try {
          final productDoc = await FirebaseFirestore.instance.collection('products').doc(doc.id).get();
          if (context.mounted) Navigator.pop(context); // Close loading dialog
          
          if (productDoc.exists && context.mounted) {
            final productData = productDoc.data() as Map<String, dynamic>;
            productData['id'] = productDoc.id;
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: productData),
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Product details no longer available.")),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error fetching product: $e")),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              height: 70, 
              width: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                      )
                    : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? "Product Name", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("₹${data['price']}", 
                    style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => doc.reference.delete(), 
            ),
          ],
        ),
      ),
    );
  }
}