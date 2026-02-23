import 'package:flutter/material.dart';
import 'dashboard.dart';    
import 'shop_screen.dart';  
import 'scan_screen.dart'; 
import 'statistics_screen.dart'; 
import 'profile_screen.dart'; 
import 'theme/twinmart_theme.dart';
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0; 
  String? _selectedCategory;

  void _handleNavigationRequest(int index, {String? category}) {
    setState(() {
      _selectedIndex = index;
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = TwinMartTheme.brandGreen;

    final List<Widget> _pages = [
      DashboardScreen(
        onScanRequest: () => _handleNavigationRequest(2), 
        onShopRequest: (cat) => _handleNavigationRequest(1, category: cat), 
        onBudgetRequest: () => _handleNavigationRequest(3)
      ),
      ShopScreen(initialCategory: _selectedCategory),
      ScanScreen(onBackToDashboard: () => _handleNavigationRequest(0)),
      StatisticsScreen(onBackToDashboard: () => _handleNavigationRequest(0)),
      // Pass the navigation handler here
      ProfileScreen(onBackToDashboard: () => _handleNavigationRequest(0)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: twinGreen, 
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Shop'),
                BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Budget'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}