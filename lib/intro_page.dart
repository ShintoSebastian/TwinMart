import 'package:flutter/material.dart';
import 'main_wrapper.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<Offset> _slide1;
  late Animation<Offset> _slide2;
  late Animation<Offset> _slide3;
  late Animation<Offset> _slide4;

  late Animation<double> _fade1;
  late Animation<double> _fade2;
  late Animation<double> _fade3;
  late Animation<double> _fade4;

  @override
  void initState() {
    super.initState();

    // ⏱ Longer duration for clear sequential animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // ✅ NON-OVERLAPPING INTERVALS (1 → 2 → 3 → 4)
    _slide1 = _buildSlide(0.0, 0.25);
    _slide2 = _buildSlide(0.25, 0.5);
    _slide3 = _buildSlide(0.5, 0.75);
    _slide4 = _buildSlide(0.75, 1.0);

    _fade1 = _buildFade(0.0, 0.25);
    _fade2 = _buildFade(0.25, 0.5);
    _fade3 = _buildFade(0.5, 0.75);
    _fade4 = _buildFade(0.75, 1.0);

    _controller.forward();
  }

  Animation<Offset> _buildSlide(double start, double end) {
    return Tween<Offset>(
      begin: const Offset(0, -0.45), // ⬇ real drop-down effect
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  Animation<double> _buildFade(double start, double end) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwinMartTheme.bgLight,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -100,
            left: -100,
            size: 300,
            color: TwinMartTheme.brandGreen.withOpacity(0.2),
          ),
          TwinMartTheme.bgBlob(
            bottom: -50,
            right: -80,
            size: 280,
            color: TwinMartTheme.brandBlue.withOpacity(0.15),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: _goToDashboard,
                        child: const Text("Skip",
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TwinMartTheme.brandLogo(size: 32),
                        const SizedBox(width: 12),
                        TwinMartTheme.brandText(fontSize: 32),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Welcome 👋",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Everything you need in one smart app",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _animatedTile(
                              _slide1,
                              _fade1,
                              const FeatureTile(
                                icon: Icons.account_balance_wallet_rounded,
                                color: TwinMartTheme.brandGreen,
                                title: "Smart Budget",
                                description:
                                    "Set monthly budgets, track expenses, and get alerts when you're near your limit.",
                              ),
                            ),
                            const SizedBox(height: 20),
                            _animatedTile(
                              _slide2,
                              _fade2,
                              const FeatureTile(
                                icon: Icons.qr_code_scanner,
                                color: TwinMartTheme.brandGreen,
                                title: "Scan & Shop",
                                description:
                                    "Scan barcodes in-store, track spending, and skip the queue with self-checkout.",
                              ),
                            ),
                            const SizedBox(height: 20),
                            _animatedTile(
                              _slide3,
                              _fade3,
                              const FeatureTile(
                                icon: Icons.shopping_bag_rounded,
                                color: Colors.orange,
                                title: "Online Store",
                                description:
                                    "Browse products, add to wishlist, and order for delivery or pickup.",
                              ),
                            ),
                            const SizedBox(height: 20),
                            _animatedTile(
                              _slide4,
                              _fade4,
                              const FeatureTile(
                                icon: Icons.bar_chart_rounded,
                                color: Colors.purple,
                                title: "Statistical Report",
                                description:
                                    "View monthly spending reports, purchase trends, and performance summaries.",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _goToDashboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TwinMartTheme.brandGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Let's Go →",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedTile(
    Animation<Offset> slide,
    Animation<double> fade,
    Widget child,
  ) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }
}

/// 🔥 FEATURE TILE (HOVER + TAP ANIMATION)
class FeatureTile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  State<FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<FeatureTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (mounted) setState(() => _isHovered = true);
        },
        onTapUp: (_) {
          if (mounted) setState(() => _isHovered = false);
        },
        onTapCancel: () {
          if (mounted) setState(() => _isHovered = false);
        },
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withOpacity(0.85)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? widget.color.withOpacity(0.4)
                    : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.06),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      Icon(widget.icon, color: widget.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.description,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
