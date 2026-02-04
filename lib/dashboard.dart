import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onScanRequest;
  final VoidCallback onShopRequest;
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
  // --- ADDED: Tracker for category filtering ---
  String selectedCategoryName = "All Products";

  static const Color brandGreen = Color(0xFF1DB98A);
  static const Color brandBlue = Color(0xFF2196F3);
  static const Color darkText = Color(0xFF2D3436);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFA),
      body: Stack(
        children: [
          _bgBlob(
            top: -160,
            left: -120,
            size: 380,
            color: brandGreen.withOpacity(0.32),
          ),
          _bgBlob(
            top: 240,
            right: -160,
            size: 420,
            color: brandBlue.withOpacity(0.28),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(),
                        const SizedBox(height: 20),
                        Center(child: _buildOnlineOfflineToggle()),
                        const SizedBox(height: 30),
                        if (isOnline) ...[
                          // --- UPDATED: Passing selected category to ShopScreen ---
                          const ShopScreen(),
                        ] else ...[
                          _buildMainActionCards(),
                          const SizedBox(height: 20),
                          HoverScale(child: _buildCartCard()),
                          const SizedBox(height: 20),
                          HoverScale(child: _buildBudgetSection()),
                          const SizedBox(height: 30),
                          _buildRecentlyScanned(),
                          const SizedBox(height: 30),
                          _buildMonthlyGraph(),
                        ],
                        const SizedBox(height: 120),
                      ],
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

  // ================= BACKGROUND =================
  Widget _bgBlob({
    double? top,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: Container(color: Colors.transparent),
        ),
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
        children: const [
          CircleAvatar(
            backgroundColor: brandGreen,
            child: Icon(Icons.shopping_cart, color: Colors.white),
          ),
          SizedBox(width: 8),
          Text(
            "TwinMart",
            style: TextStyle(fontWeight: FontWeight.bold, color: darkText),
          ),
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
            Text(
              "Hello, $name 👋",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Scan products in-store and track your budget",
              style: TextStyle(color: Colors.grey.shade600),
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
              title: "Budget",
              desc: "Track Spending",
              icon: Icons.account_balance_wallet_outlined,
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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Monthly Budget",
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 8),
            Text(
              "₹5,000",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ================= RECENT =================
  Widget _buildRecentlyScanned() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Recently Scanned",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  // ================= GRAPH =================
  Widget _buildMonthlyGraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Monthly Statistics",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _graphBar("Items", 0.85),
            _graphBar("Spend", 0.65),
            _graphBar("Saved", 0.45),
            _graphBar("Trips", 0.75),
          ],
        ),
      ],
    );
  }

  Widget _graphBar(String label, double value) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          height: 150 * value,
          width: 26,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [brandBlue, brandGreen],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
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
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
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