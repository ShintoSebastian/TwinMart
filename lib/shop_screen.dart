import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_provider.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;

class ShopScreen extends StatefulWidget {
  final bool isEmbedded;
  final String? initialCategory;
  const ShopScreen({super.key, this.isEmbedded = false, this.initialCategory});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String selectedCategoryName = "All Products";
  String searchQuery = "";
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      selectedCategoryName = widget.initialCategory!;
    }
  }

  @override
  void didUpdateWidget(ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != null && widget.initialCategory != oldWidget.initialCategory) {
      setState(() {
        selectedCategoryName = widget.initialCategory!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = TwinMartTheme.brandGreen;

    if (widget.isEmbedded) {
      return LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageTitle(),
              _buildSubHeader(twinGreen),
              _buildDynamicCategoryBar(twinGreen),
              const SizedBox(height: 20),
              _buildDynamicProductContent(twinGreen, crossAxisCount),
            ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: TwinMartTheme.bgLight,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -150,
            left: -100,
            size: 350,
            color: TwinMartTheme.brandGreen.withOpacity(0.25),
          ),
          TwinMartTheme.bgBlob(
            bottom: -50,
            right: -80,
            size: 300,
            color: TwinMartTheme.brandBlue.withOpacity(0.2),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
                double hPad = constraints.maxWidth > 1200 ? constraints.maxWidth * 0.05 : 20.0;

                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 50),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: _buildPageTitle(),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: _buildSubHeader(twinGreen),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: _buildDynamicCategoryBar(twinGreen),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                            child: _buildDynamicProductContent(twinGreen, crossAxisCount),
                          ),
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                    _buildFloatingCartBar(twinGreen),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isEmbedded) ...[
              Row(
                children: [
                  TwinMartTheme.brandLogo(size: 20),
                  const SizedBox(width: 8),
                  TwinMartTheme.brandText(fontSize: 20),
                ],
              ),
              const SizedBox(height: 15),
            ],
            const Text("Browse Products",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: TwinMartTheme.darkText)),
            const Text("Discover fresh groceries and essentials",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _buildSubHeader(Color green) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: green.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: const InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _iconBox(
            icon: isGridView ? Icons.grid_view_rounded : Icons.list_rounded,
            green: green,
            onTap: () => setState(() => isGridView = !isGridView),
          ),
          const SizedBox(width: 10),
          Consumer<CartProvider>(
            builder: (context, cart, child) => _iconBox(
              icon: Icons.shopping_cart,
              green: green,
              badge: cart.itemCount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox({
    required IconData icon,
    required Color green,
    VoidCallback? onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: green.withOpacity(0.5)),
            ),
            child: Icon(icon, color: green),
          ),
          if (badge > 0)
            Positioned(
              right: -6,
              top: -6,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: Colors.red,
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDynamicCategoryBar(Color green) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final cats = [
          {"name": "All Products", "emoji": "🛒"},
          ...snapshot.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return {
              "name": d['name'] ?? "Category",
              "emoji": d['emoji'] ?? "🛍️"
            };
          })
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cats.map((c) {
              final active = selectedCategoryName == c['name'];
              return GestureDetector(
                onTap: () =>
                    setState(() => selectedCategoryName = c['name'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12, bottom: 10, top: 5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? green : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: active ? green.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(c['emoji'] as String, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        c['name'] as String,
                        style: TextStyle(
                            color: active ? Colors.white : TwinMartTheme.darkText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDynamicProductContent(Color green, int count) {
    Query query = FirebaseFirestore.instance.collection('products');

    if (selectedCategoryName != "All Products") {
      query = query.where('category', isEqualTo: selectedCategoryName);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var products = snapshot.data!.docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          d['id'] = doc.id;
          return d;
        }).toList();

        if (searchQuery.isNotEmpty) {
          products = products.where((p) =>
              (p['name'] ?? "")
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase())).toList();
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.82,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) =>
              _ProductCard(product: products[i], green: green),
        );
      },
    );
  }

  Widget _buildFloatingCartBar(Color green) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        if (cart.itemCount == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "View Cart (${cart.itemCount} items)",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color green;

  const _ProductCard({
    required this.product,
    required this.green,
  });

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
        'name': product['name'],
        'price': product['price'],
        'imageUrl': product['imageUrl'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final String productId = product['id'] ?? "";
    final double price = (product['price'] ?? 0).toDouble();
    final int qty = cart.items[productId]?.quantity ?? 0;

    final dynamic rawUrl = product['imageUrl'];
    final String? imageUrl = (rawUrl is String && rawUrl.trim().isNotEmpty) ? rawUrl.trim() : null;

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Hero(
                      tag: 'product-$productId',
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              height: 75,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Text("🛍️", style: TextStyle(fontSize: 38)),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            )
                          : const Text("🛍️", style: TextStyle(fontSize: 38)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['name'] ?? "Product",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (product['offerLine'] != null && product['offerLine'].toString().isNotEmpty)
                   Padding(
                     padding: const EdgeInsets.only(top: 2),
                     child: Text(
                       product['offerLine'],
                       style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                     ),
                   ),
                const SizedBox(height: 4),
                // Price Section (Amazon Style)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product['originalPrice'] != null && (product['originalPrice'] as num) > price)
                      Text(
                        "₹${(product['originalPrice'] as num).toInt()}",
                        style: const TextStyle(color: Colors.grey, fontSize: 10, decoration: TextDecoration.lineThrough),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "₹${price.toInt()}",
                            style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900),
                          ),
                        ),
                        _buildCartButton(cart, productId, price, imageUrl),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text("*including bank and coupon offer", style: TextStyle(color: Colors.grey, fontSize: 7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (userId.isNotEmpty)
          Positioned(
            top: 8,
            right: 8,
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('wishlist')
                  .doc(productId)
                  .snapshots(),
              builder: (context, snapshot) {
                final bool isInWishlist = snapshot.hasData && snapshot.data!.exists;
                return GestureDetector(
                  onTap: () => _toggleWishlist(userId, productId),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCartButton(CartProvider cart, String productId, double price, String? imageUrl) {
    final int qty = cart.items[productId]?.quantity ?? 0;
    
    if (qty == 0) {
      return GestureDetector(
        onTap: () {
          cart.addToCart({
            'id': productId,
            'name': product['name'],
            'price': price,
            'image': imageUrl ?? "🛍️",
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Text(
            "Add to Cart",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
      );
    } else {
      return Container(
        height: 36,
        constraints: const BoxConstraints(minWidth: 90),
        decoration: BoxDecoration(
          color: green,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => cart.removeSingleItem(productId),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                    qty == 1 ? Icons.delete_outline : Icons.remove,
                    color: Colors.white,
                    size: 18),
              ),
            ),
            Text(
              qty.toString(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white),
            ),
            GestureDetector(
              onTap: () {
                cart.addToCart({
                  'id': productId,
                  'name': product['name'],
                  'price': price,
                  'image': imageUrl ?? "🛍️",
                });
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      );
    }
  }
}