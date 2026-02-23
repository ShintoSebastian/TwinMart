import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';
import 'product_details_screen.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onScanRequest;
  final Function(String?) onShopRequest;
  final VoidCallback onBudgetRequest;

  const DashboardScreen({
    super.key,
    required this.onScanRequest,
    required this.onShopRequest,
    required this.onBudgetRequest,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isOnline = false;
  String selectedCategoryName = "All Products";
  
  // --- ADDED: Controller and Timer for Banner ---
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  int _bannerCount = 3; // Default fallback
  late Timer _bannerTimer;

  static const Color brandGreen = TwinMartTheme.brandGreen;
  static const Color brandBlue = TwinMartTheme.brandBlue;
  static const Color darkText = TwinMartTheme.darkText;

  @override
  void initState() {
    super.initState();
    // Auto-slide logic for banner
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients && _bannerCount > 0) {
        int nextPage = _currentBannerIndex + 1;
        _bannerController.animateToPage(
          nextPage % _bannerCount,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_twilight_rounded;
    return Icons.nights_stay_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwinMartTheme.bgLight,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -160,
            left: -120,
            size: 380,
            color: TwinMartTheme.brandGreen.withOpacity(0.32),
          ),
          TwinMartTheme.bgBlob(
            top: 240,
            right: -160,
            size: 420,
            color: TwinMartTheme.brandBlue.withOpacity(0.28),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          _buildWelcomeHeader(),
                          const SizedBox(height: 25),
                          _buildPromotionalCarousel(), // Functional Banner
                          const SizedBox(height: 30),
                          Center(child: _buildOnlineOfflineToggle()),
                          const SizedBox(height: 30),
                          if (isOnline) ...[
                            const ShopScreen(isEmbedded: true),
                          ] else ...[
                            _buildMainActionCards(),
                            const SizedBox(height: 20),
                            HoverScale(child: _buildCartCard()),
                            const SizedBox(height: 20),
                            HoverScale(child: _buildBudgetSection()),
                            const SizedBox(height: 30),
                            _buildRecentlyScanned(),
                          ],
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= APP BAR =================
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          TwinMartTheme.brandLogo(size: 20),
          const SizedBox(width: 8),
          TwinMartTheme.brandText(fontSize: 22),
        ],
      ),
      actions: [
        const Icon(Icons.notifications_none, color: darkText),
        const SizedBox(width: 12),

        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get(),
          builder: (context, snapshot) {
            final name = snapshot.data?['name'] ?? "User";
            final initial =
                name.toString().isNotEmpty ? name[0].toUpperCase() : "U";

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      onBackToDashboard: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundColor: brandGreen,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ================= PROMOTIONAL CAROUSEL =================
  Widget _buildPromotionalCarousel() {
    return SizedBox(
      height: 160,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promotions')
            .orderBy('order', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          // If Firestore has data, use it. Otherwise, use fallbacks.
          List<Widget> bannerWidgets = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            _bannerCount = snapshot.data!.docs.length;
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              bannerWidgets.add(
                _buildBannerCard(
                  title: data['title'] ?? "Special Offer",
                  subtitle: data['subtitle'] ?? "Claim yours now!",
                  btnText: data['btnText'] ?? "Shop Now",
                  icon: _getIconData(data['icon'] ?? "local_grocery_store"),
                  gradient: _getGradient(data['gradientType'] ?? "green"),
                  onTap: () {
                    final action = data['action'] ?? "online_shop";
                    if (action == "budget_screen") {
                      widget.onBudgetRequest();
                    } else {
                      final category = data['targetCategory'];
                      widget.onShopRequest(category);
                    }
                  },
                ),
              );
            }
          } else {
            _bannerCount = 3;
            // FALLBACK HARDCODED BANNERS
            bannerWidgets = [
              _buildBannerCard(
                title: "Fresh Finds",
                subtitle: "Up to 30% Off Groceries",
                btnText: "Shop Now",
                icon: Icons.local_grocery_store_rounded,
                gradient: const [Color(0xFF1DB98A), Color(0xFF15A196)],
                onTap: () => widget.onShopRequest(null),
              ),
              _buildBannerCard(
                title: "Tech Week",
                subtitle: "Exclusive Desktop Deals",
                btnText: "Explore",
                icon: Icons.devices_other_rounded,
                gradient: const [Color(0xFF2196F3), Color(0xFF1976D2)],
                onTap: () => widget.onShopRequest("digital"), // Assuming digital is a category
              ),
              _buildBannerCard(
                title: "Smart Budgeting",
                subtitle: "Track every rupee accurately",
                btnText: "Set Limit",
                icon: Icons.account_balance_wallet_rounded,
                gradient: const [Color(0xFFFF9800), Color(0xFFF57C00)],
                onTap: widget.onBudgetRequest,
              ),
            ];
          }

          return PageView(
            controller: _bannerController,
            onPageChanged: (index) {
                _currentBannerIndex = index;
            },
            children: bannerWidgets,
          );
        },
      ),
    );
  }

  // Helper to get IconData from string (matching Admin input)
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'electronics': return Icons.devices_other_rounded;
      case 'budget': return Icons.account_balance_wallet_rounded;
      case 'savings': return Icons.savings_rounded;
      case 'stars': return Icons.stars_rounded;
      default: return Icons.local_grocery_store_rounded;
    }
  }

  // Helper to get Gradient from preset names
  List<Color> _getGradient(String type) {
    switch (type) {
      case 'blue': return [const Color(0xFF2196F3), const Color(0xFF1976D2)];
      case 'orange': return [const Color(0xFFFF9800), const Color(0xFFF57C00)];
      case 'purple': return [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)];
      default: return [const Color(0xFF1DB98A), const Color(0xFF15A196)];
    }
  }

  Widget _buildBannerCard({
    required String title,
    required String subtitle,
    required String btnText,
    required IconData icon,
    required List<Color> gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => widget.onShopRequest(null),
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.35), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Stack(
          children: [
            Positioned(right: -20, bottom: -20, child: Icon(icon, color: Colors.white.withOpacity(0.15), size: 140)),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: onTap ?? () => widget.onShopRequest(null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: gradient.first,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    ),
                    child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildWelcomeHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        final name = snapshot.data?['name']?.split(' ')[0] ?? "User";
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getGreetingIcon(), color: brandGreen, size: 28),
                const SizedBox(width: 10),
                Text(
                  "${_getGreeting()}, $name",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Experience the future of shopping.",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        );
      },
    );
  }

  // ================= TOGGLE =================
  Widget _buildOnlineOfflineToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem("Online", Icons.wifi, isOnline,
              () => setState(() => isOnline = true)),
          _toggleItem("Offline", Icons.wifi_off, !isOnline,
              () => setState(() => isOnline = false)),
        ],
      ),
    );
  }

  Widget _toggleItem(
      String text, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? brandGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: active ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ACTION CARDS =================
  Widget _buildMainActionCards() {
    return Row(
      children: [
        Expanded(
          child: HoverScale(
            child: _buildActionCard(
              title: "Scan Products",
              desc: "Barcode Scanner",
              icon: Icons.qr_code_scanner,
              color: brandGreen,
              onTap: widget.onScanRequest,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: HoverScale(
            child: _buildActionCard(
              title: "Budget & Stats",
              desc: "Financial Insights",
              icon: Icons.bar_chart_rounded,
              color: Colors.orange,
              onTap: widget.onBudgetRequest,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(desc, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  // ================= CART =================
  Widget _buildCartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: brandGreen,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: const [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.shopping_bag, color: Colors.white),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Current Cart",
                    style: TextStyle(color: Colors.white70)),
                Text(
                  "0 items",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUDGET =================
  Widget _buildBudgetSection() {
    return GestureDetector(
      onTap: widget.onBudgetRequest,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [brandBlue, brandGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('budget')
              .doc('settings')
              .snapshots(),
          builder: (context, snapshot) {
            double budget = 5000.0;
            double savings = 0.0;
            
            if (snapshot.hasData && snapshot.data!.exists) {
               final data = snapshot.data!.data() as Map<String, dynamic>?;
               if (data != null) {
                 budget = (data['budget_limit'] ?? 5000.0).toDouble();
                 savings = (data['total_savings'] ?? 0.0).toDouble();
               }
            }

            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Monthly Budget", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 5),
                      Text("₹${budget.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                const SizedBox(width: 25),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Total Saved", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.amberAccent, size: 20),
                          const SizedBox(width: 5),
                          Text("₹${savings.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentlyScanned() {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recently Scanned",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('recently_scanned')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text("No items scanned yet", style: TextStyle(color: Colors.grey[600], fontSize: 13));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final String imageUrl = data['imageUrl'] ?? "";
                  final String name = data['name'] ?? "Item";

                  return GestureDetector(
                    onTap: () async {
                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final productDoc = await FirebaseFirestore.instance
                            .collection('products')
                            .doc(doc.id)
                            .get();
                        Navigator.pop(context); // Close loading

                        if (productDoc.exists && context.mounted) {
                          final productData = productDoc.data() as Map<String, dynamic>;
                          productData['id'] = productDoc.id;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(product: productData),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Product details not available.")),
                          );
                        }
                      } catch (e) {
                        Navigator.pop(context); // Close loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 15),
                      child: Column(
                        children: [
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
                              ],
                            ),
                            child: Hero(
                              tag: 'product-${doc.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey))
                                    : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }


}

class HoverScale extends StatefulWidget {
  final Widget child;
  const HoverScale({super.key, required this.child});

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => hovering = true);
      },
      onExit: (_) {
        if (mounted) setState(() => hovering = false);
      },
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: hovering ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}