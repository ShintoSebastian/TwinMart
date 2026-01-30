import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart'; // Import only

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the cart provider
    final cart = Provider.of<CartProvider>(context);
    const Color twinGreen = Color(0xFF1DB98A);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        title: const Text('My Cart', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              onPressed: () => _showClearCartDialog(context, cart),
            )
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      // Correctly access alphanumeric map values
                      CartItem item = cart.items.values.toList()[index];
                      return _buildCartItem(item, cart, twinGreen);
                    },
                  ),
                ),
                _buildSummary(cart, twinGreen),
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

  Widget _buildCartItem(CartItem item, CartProvider cart, Color green) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Row(
        children: [
          // Dynamic image (Emoji or Admin-uploaded URL)
          Container(
            height: 70,
            width: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(15)),
            child: Text(item.image, style: const TextStyle(fontSize: 35)),
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
          // --- +/- Quantity Controls ---
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
    );
  }

  Widget _buildSummary(CartProvider cart, Color green) {
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
                  // Checkout implementation logic
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