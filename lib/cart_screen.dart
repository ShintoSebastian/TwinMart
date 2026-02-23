import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_provider.dart'; 
import 'product_details_screen.dart';
import 'payment_methods_screen.dart';
import 'theme/twinmart_theme.dart';
import 'dart:ui' as ui;

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    const Color twinGreen = Color(0xFF1DB98A);

    return Scaffold(
      backgroundColor: TwinMartTheme.bgLight,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -100,
            right: -80,
            size: 280,
            color: TwinMartTheme.brandGreen.withOpacity(0.15),
          ),
          TwinMartTheme.bgBlob(
            bottom: 100,
            left: -100,
            size: 320,
            color: TwinMartTheme.brandBlue.withOpacity(0.12),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Column(
              children: [
                _buildAppBar(context, cart),
                Expanded(
                  child: cart.items.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            CartItem item = cart.items.values.toList()[index];
                            return _buildCartItem(context, item, cart, TwinMartTheme.brandGreen);
                          },
                        ),
                ),
                if (cart.items.isNotEmpty) _buildSummary(context, cart, TwinMartTheme.brandGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, CartProvider cart) {
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
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              onPressed: () => _showClearCartDialog(context, cart),
            )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Your cart is empty", style: TextStyle(color: Colors.blueGrey, fontSize: 18, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartProvider cart, Color green) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: GestureDetector(
        onTap: () async {
          // Show a loading indicator while fetching full details
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );
          
          try {
            final doc = await FirebaseFirestore.instance.collection('products').doc(item.id).get();
            Navigator.pop(context); // Close loading dialog
            
            if (doc.exists && context.mounted) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: data),
                ),
              );
            }
          } catch (e) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error fetching product details: $e")),
            );
          }
        },
        child: Row(
          children: [
            // ✅ UPDATED IMAGE CONTAINER
            Container(
              height: 70,
              width: 70,
              clipBehavior: Clip.antiAlias, 
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9), 
                borderRadius: BorderRadius.circular(15)
              ),
              child: Hero(
              tag: 'product-${item.id}',
              child: (item.image.startsWith('http'))
                  ? Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : Center(child: Text(item.image, style: const TextStyle(fontSize: 35))),
            ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('₹${item.price.toStringAsFixed(2)}', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF4F9F8), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18), 
                    onPressed: () => cart.removeSingleItem(item.id)
                  ),
                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.add, color: green, size: 18), 
                    onPressed: () => cart.addToCart({
                      'id': item.id,
                      'name': item.name,
                      'price': item.price,
                      'image': item.image,
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartProvider cart, Color green) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))]
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text('₹${cart.totalAmount.toStringAsFixed(2)}', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentMethodsScreen(
                        amount: cart.totalAmount,
                        items: cart.items.values.map((item) => {
                          'id': item.id,
                          'name': item.name,
                          'price': item.price,
                          'quantity': item.quantity,
                          'image': item.image,
                          'category': item.category,
                        }).toList(),
                        isOnlineOrder: true,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: green, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0
                ),
                child: const Text('Confirm Order', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Cart?"),
        content: const Text("Are you sure you want to remove all items from your cart?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No")),
          TextButton(onPressed: () {
            cart.clearCart();
            Navigator.pop(ctx);
          }, child: const Text("Yes, Clear")),
        ],
      ),
    );
  }
}