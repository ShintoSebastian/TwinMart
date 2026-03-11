import 'package:flutter/material.dart';
import 'dashboard.dart';    
import 'shop_screen.dart';  
import 'scan_screen.dart'; 
import 'statistics_screen.dart'; 
import 'profile_screen.dart'; 
import 'theme/twinmart_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0; 
  String? _selectedCategory;
  final Timestamp _appStartTime = Timestamp.now();

  @override
  void initState() {
    super.initState();
    _listenForGlobalNotifications();
  }

  void _listenForGlobalNotifications() {
    final DateTime listenerStartTime = DateTime.now().subtract(const Duration(seconds: 5));
    debugPrint("🔔 [TwinMart] Notification Listener active. (Start: $listenerStartTime)");

    FirebaseFirestore.instance
        .collection('broadcasts')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final Timestamp? ts = data['timestamp'] as Timestamp?;
          
          // Skip if no timestamp yet (optimistic local add) or if it's an old notification
          if (ts == null) continue; 
          if (ts.toDate().isBefore(listenerStartTime)) continue;

          debugPrint("🎁 [TwinMart] VERIFIED New Broadcast: ${data['title']}");

          final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
          if (uid.isEmpty) continue;

          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          bool isPromosOn = true; 
          if (userDoc.exists) {
            final Map<String, dynamic> userData = userDoc.data() ?? {};
            final Map<String, dynamic> notifications = userData['notifications'] ?? {};
            isPromosOn = notifications['promotionalOffers'] ?? true;
          }

          if (isPromosOn && data['type'] == 'promotion') {
            NotificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: data['title'] ?? "New Promotion",
              body: data['body'] ?? "Check out the latest deals!",
            );
          }
        }
      }
    });
  }

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
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: twinGreen, 
              unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey,
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