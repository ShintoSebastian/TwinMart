import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_provider.dart';
import 'payment_methods_screen.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  final Color twinGreen = const Color(0xFF1DB98A);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final String productId = widget.product['id'] ?? "";
    final double price = (widget.product['price'] ?? 0).toDouble();
    final String name = widget.product['name'] ?? "Product";
    final String aboutItem = widget.product['about'] ?? "";
    
    // ✅ Handle images: Ensure main imageUrl is ALWAYS first
    final List<String> images = [];
    final String? mainImage = widget.product['imageUrl'];
    
    if (mainImage != null && mainImage.toString().isNotEmpty) {
      images.add(mainImage);
    }
    
    if (widget.product['images'] != null && widget.product['images'] is List) {
      for (var img in widget.product['images']) {
        String imgStr = img.toString();
        if (imgStr.isNotEmpty && imgStr != mainImage) {
          images.add(imgStr);
        }
      }
    }

    // Handle specifications
    final Map<String, dynamic> specs = widget.product['specifications'] ?? {};

    return Scaffold(
      backgroundColor: TwinMartTheme.bgLight,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: 100,
            right: -100,
            size: 300,
            color: TwinMartTheme.brandGreen.withOpacity(0.15),
          ),
          TwinMartTheme.bgBlob(
            bottom: -50,
            left: -80,
            size: 280,
            color: TwinMartTheme.brandBlue.withOpacity(0.1),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(images),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(name, price),
                        const SizedBox(height: 15),
                        _buildDivider(),
                        if (aboutItem.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildSectionTitle("About this item"),
                          const SizedBox(height: 10),
                          ...aboutItem.split('\n').where((line) => line.trim().isNotEmpty).map((line) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("• ",
                                        style: TextStyle(
                                            color: TwinMartTheme.brandGreen,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Expanded(
                                      child: Text(
                                        line.trim(),
                                        style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 15,
                                            height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                        const SizedBox(height: 25),
                        if (specs.isNotEmpty) ...[
                          _buildSectionTitle("Specifications"),
                          const SizedBox(height: 10),
                          _buildSpecsList(specs),
                          const SizedBox(height: 25),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom App Bar (Floating)
          _buildCustomAppBar(),

          // Bottom Action Bar
          _buildBottomAction(cart, productId, name, price, images.isNotEmpty ? images[0] : "🛍️"),
        ],
      ),
    );
  }

  Widget _buildImageSection(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 350,
        width: double.infinity,
        color: Colors.grey[100],
        child: const Center(child: Text("🛍️", style: TextStyle(fontSize: 80))),
      );
    }

    return Column(
      children: [
        Container(
          height: 400,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white, // ✅ Blend with product image background
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) => setState(() => _currentImageIndex = index),
                  itemBuilder: (context, index) {
                    Widget imageWidget = Container(
                      color: Colors.white,
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        panEnabled: false,
                        child: Image.network(
                          images[index],
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                          isAntiAlias: true,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text("🛍️", style: TextStyle(fontSize: 80))),
                        ),
                      ),
                    );

                    if (index == 0) {
                      return Hero(
                        tag: 'product-${widget.product['id']}',
                        child: imageWidget,
                      );
                    }
                    return imageWidget;
                  },
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentImageIndex == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index ? twinGreen : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomAppBar() {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final String productId = widget.product['id'] ?? "";

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circleButton(
              icon: Icons.arrow_back_ios_new,
              onPressed: () => Navigator.pop(context),
            ),
            if (userId.isNotEmpty)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('wishlist')
                    .doc(productId)
                    .snapshots(),
                builder: (context, snapshot) {
                  final bool isInWishlist = snapshot.hasData && snapshot.data!.exists;
                  return _circleButton(
                    icon: isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: isInWishlist ? Colors.red : Colors.black87,
                    onPressed: () => _toggleWishlist(userId, productId),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onPressed, Color color = Colors.black87}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildHeader(String name, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1C252E)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "₹${price.toInt()}",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: twinGreen),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: twinGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "In Stock",
                style: TextStyle(color: Color(0xFF1DB98A), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      color: Colors.grey[200],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C252E)),
    );
  }

  Widget _buildSpecsList(Map<String, dynamic> specs) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: specs.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entry.key,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomAction(CartProvider cart, String id, String name, double price, String image) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
        ),
        child: Row(
          children: [
            // Add to Cart / Quantity Controller
            Expanded(
              child: _buildAddToCartButton(cart, id, name, price, image),
            ),
            const SizedBox(width: 15),
            // Buy Now
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentMethodsScreen(
                        amount: price,
                        items: [{
                          'id': id,
                          'name': name,
                          'price': price,
                          'quantity': 1,
                          'image': image,
                        }],
                        isOnlineOrder: true,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C252E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 58),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: const Text("Buy Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(CartProvider cart, String id, String name, double price, String image) {
    final int qty = cart.items[id]?.quantity ?? 0;

    if (qty > 0) {
      return Container(
        height: 58,
        decoration: BoxDecoration(
          color: twinGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(qty == 1 ? Icons.delete_outline : Icons.remove, color: twinGreen),
              onPressed: () => cart.removeSingleItem(id),
            ),
            Text(
              qty.toString(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: twinGreen),
            ),
            IconButton(
              icon: Icon(Icons.add, color: twinGreen),
              onPressed: () => cart.addToCart({
                'id': id,
                'name': name,
                'price': price,
                'image': image,
              }),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: () {
        cart.addToCart({
          'id': id,
          'name': name,
          'price': price,
          'image': image,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$name added to cart"),
            backgroundColor: twinGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: twinGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      child: const Text("Add to Cart", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _toggleWishlist(String userId, String productId) async {
    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(productId);

    final doc = await wishlistRef.get();

    if (doc.exists) {
      await wishlistRef.delete();
    } else {
      await wishlistRef.set({
        'name': widget.product['name'],
        'price': widget.product['price'],
        'imageUrl': widget.product['imageUrl'] ?? (widget.product['images'] != null ? widget.product['images'][0] : ""),
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
}
