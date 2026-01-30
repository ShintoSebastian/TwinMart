import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_provider.dart';
import 'cart_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String selectedCategoryId = "all";
  String searchQuery = "";
  bool isGridView = true;

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = Color(0xFF1DB98A);

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount =
            constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
        double hPad =
            constraints.maxWidth > 1200 ? constraints.maxWidth * 0.05 : 20.0;

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    padding:
                        EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                    child:
                        _buildDynamicProductContent(twinGreen, crossAxisCount),
                  ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
            _buildFloatingCartBar(twinGreen),
          ],
        );
      },
    );
  }

  // ================= PAGE TITLE =================

  Widget _buildPageTitle() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Browse Products",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text("Discover fresh groceries and essentials",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  // ================= SEARCH / GRID / CART =================

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
                border: Border.all(color: green.withOpacity(0.6)),
              ),
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: const InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
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

  // ================= CATEGORY BAR =================

  Widget _buildDynamicCategoryBar(Color green) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final cats = [
          {"id": "all", "name": "All Products", "emoji": "🛒"},
          ...snapshot.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return {
              "id": doc.id,
              "name": d['name'] ?? "Category",
              "emoji": d['emoji'] ?? "🛍️"
            };
          })
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cats.map((c) {
              final active = selectedCategoryId == c['id'];
              return GestureDetector(
                onTap: () =>
                    setState(() => selectedCategoryId = c['id'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? green : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Text(c['emoji'] as String),
                      const SizedBox(width: 8),
                      Text(
                        c['name'] as String,
                        style: TextStyle(
                            color: active ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold),
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

  // ================= PRODUCTS =================

  Widget _buildDynamicProductContent(Color green, int count) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          d['id'] = doc.id;
          return d;
        }).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) =>
              _ProductCard(product: products[i], green: green),
        );
      },
    );
  }

  // ================= FLOATING CART =================

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

// ================= PRODUCT CARD =================

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color green;

  const _ProductCard({
    required this.product,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final String productId = product['id'];
    final double price = (product['price'] ?? 0).toDouble();
    final int qty = cart.items[productId]?.quantity ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
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
              child: Text(product['image'] ?? "🛍️",
                  style: const TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product['name'] ?? "Product",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("₹$price",
                  style: TextStyle(
                      color: green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),

              // ➕➖ ADD / QUANTITY CONTROL
              qty == 0
                  ? GestureDetector(
                      onTap: () {
                        cart.addToCart({
                          'id': productId,
                          'name': product['name'],
                          'price': price,
                          'image': product['image'] ?? "🛍️",
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add,
                                size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text("Add",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: green),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, color: green, size: 18),
                            onPressed: () =>
                                cart.removeSingleItem(productId),
                          ),
                          Text(
                            qty.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: green, size: 18),
                            onPressed: () {
                              cart.addToCart({
                                'id': productId,
                                'name': product['name'],
                                'price': price,
                                'image': product['image'] ?? "🛍️",
                              });
                            },
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
