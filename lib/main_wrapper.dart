import 'package:flutter/material.dart';
import 'dashboard.dart';    
import 'shop_screen.dart';  
import 'scan_screen.dart'; 
import 'budget_screen.dart'; 
import 'profile_screen.dart'; 

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0; 

  void _handleNavigationRequest(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = Color(0xFF1DB98A);

    final List<Widget> _pages = [
      DashboardScreen(
        onScanRequest: () => _handleNavigationRequest(2), 
        onShopRequest: () => _handleNavigationRequest(1), 
        onBudgetRequest: () => _handleNavigationRequest(3)
      ),
      const ShopScreen(),
      ScanScreen(onBackToDashboard: () => _handleNavigationRequest(0)),
      BudgetScreen(onBackToDashboard: () => _handleNavigationRequest(0)),
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
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Budget'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}