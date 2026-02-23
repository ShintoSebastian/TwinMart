import 'package:flutter/material.dart';
import 'admin_products.dart';
import 'admin_categories.dart';
import 'admin_inventory.dart';
import 'admin_transactions.dart';
import 'admin_reports.dart';
import 'admin_users.dart';
import 'admin_promotions.dart';
import 'login.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  // Exact Theme Colors
  final Color bgDark = const Color(0xFF0F172A);
  final Color sidebarColor = const Color(0xFF1E293B);
  final Color cardDark = const Color(0xFF1E293B);
  final Color twinGreen = const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Threshold for Mobile vs Web
        bool isMobile = constraints.maxWidth < 900;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: bgDark,
          // Mobile View: Use a Drawer
          drawer: isMobile ? Drawer(child: _buildSidebarContents(true)) : null,
          appBar: isMobile 
            ? AppBar(
                title: const Text("Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: bgDark,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ) 
            : null,
          body: Row(
            children: [
              // Web View: Permanent Sidebar
              if (!isMobile)
                Container(
                  width: 260,
                  color: sidebarColor,
                  child: _buildSidebarContents(false),
                ),
              
              // Content Area
              Expanded(
                child: _getSelectedPage(isMobile),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- NAVIGATION LOGIC ---
  Widget _getSelectedPage(bool isMobile) {
    switch (_selectedIndex) {
      case 0: return _buildDashboardHome(isMobile);
      case 1: return const ManageProductsPage();
      case 2: return const ManageCategoriesPage();
      case 3: return const ManageInventoryPage();
      case 4: return const ManageTransactionsPage();
      case 5: return const ManageReportsPage();
      case 6: return const ManageUsersPage(); 
      case 7: return const ManageOffersPage();
      default: return const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.white)));
    }
  }

  // --- SHARED SIDEBAR/DRAWER CONTENT ---
  Widget _buildSidebarContents(bool isDrawer) {
    return Column(
      children: [
        _buildSidebarHeader(),
        const Divider(color: Colors.white10),
        _sidebarItem(0, Icons.grid_view_rounded, "Dashboard"),
        _sidebarItem(1, Icons.inventory_2_outlined, "Products"),
        _sidebarItem(2, Icons.category_outlined, "Categories"),
        _sidebarItem(3, Icons.warehouse_outlined, "Inventory"),
        _sidebarItem(4, Icons.receipt_long_outlined, "Transactions"),
        _sidebarItem(5, Icons.description_outlined, "Reports"),
        _sidebarItem(6, Icons.people_outline, "Manage Users"),
        _sidebarItem(7, Icons.campaign_outlined, "Manage Offers"),
        const Spacer(),
        _buildSidebarFooter(),
      ],
    );
  }

  // --- DASHBOARD HOME (THE ADAPTABLE GRID) ---
  Widget _buildDashboardHome(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) const Text("Dashboard", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // 1. STATS GRID - Now Dynamic with Real Data
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: isMobile ? 2.5 : 2.1,
            children: [
              // Total Products
              _buildStreamStatCard(
                "Total Products", 
                FirebaseFirestore.instance.collection('products').snapshots(),
                (snap) => snap.docs.length.toString(),
                Icons.inventory_2_outlined, Colors.blue, 
                () => setState(() => _selectedIndex = 1)
              ),
              
              // Categories
              _buildStreamStatCard(
                "Categories", 
                FirebaseFirestore.instance.collection('categories').snapshots(),
                (snap) => snap.docs.length.toString(),
                Icons.category_outlined, Colors.purple, 
                () => setState(() => _selectedIndex = 2)
              ),

              // Low Stock Items (Assumes stock field exists or defaults to 0)
              _buildStreamStatCard(
                "Low Stock Items", 
                FirebaseFirestore.instance.collection('products').snapshots(),
                (snap) {
                   int lowStock = snap.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      int stock = data['stock'] ?? 0;
                      return stock <= 10; // Threshold of 10
                   }).length;
                   return lowStock.toString();
                },
                Icons.warning_amber_rounded, Colors.orange, 
                () => setState(() => _selectedIndex = 3)
              ),

              // Total Transactions
              _buildStreamStatCard(
                "Total Transactions", 
                FirebaseFirestore.instance.collection('orders').snapshots(),
                (snap) => snap.docs.length.toString(),
                Icons.receipt_long_outlined, Colors.green, 
                () => setState(() => _selectedIndex = 4)
              ),

              // Total Users
              _buildStreamStatCard(
                "Total Users", 
                FirebaseFirestore.instance.collection('users').snapshots(),
                (snap) => snap.docs.length.toString(),
                Icons.people_alt_outlined, Colors.indigo, 
                () => setState(() => _selectedIndex = 6)
              ),

              // Total Revenue
              _buildStreamStatCard(
                "Total Revenue", 
                FirebaseFirestore.instance.collection('orders').snapshots(),
                (snap) {
                   double total = 0;
                   for (var doc in snap.docs) {
                     total += (doc['totalAmount'] ?? 0).toDouble();
                   }
                   return "₹${total.toInt()}";
                },
                Icons.trending_up, Colors.teal, 
                () => setState(() => _selectedIndex = 5)
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 2. QUICK ACTIONS CONTAINER
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Quick Actions", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 2 : 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isMobile ? 1.1 : 0.9,
                  children: [
                    _buildActionBtn("Manage Products", Icons.inventory_2, Colors.blue, () => setState(() => _selectedIndex = 1)),
                    _buildActionBtn("Manage Categories", Icons.category, Colors.purple, () => setState(() => _selectedIndex = 2)),
                    _buildActionBtn("Check Inventory", Icons.warehouse, Colors.orange, () => setState(() => _selectedIndex = 3)),
                    _buildActionBtn("Manage Users", Icons.person_add_alt_1, Colors.indigo, () => setState(() => _selectedIndex = 6)),
                    _buildActionBtn("Manage Offers", Icons.campaign, Colors.pinkAccent, () => setState(() => _selectedIndex = 7)),
                    _buildActionBtn("View Reports", Icons.trending_up, Colors.green, () => setState(() => _selectedIndex = 5)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI ATOM COMPONENTS ---

  Widget _buildStreamStatCard(
    String title, 
    Stream<QuerySnapshot> stream, 
    String Function(QuerySnapshot) formatter,
    IconData icon, Color color, VoidCallback onTap) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String val = "0";
        if (snapshot.hasData) {
          val = formatter(snapshot.data!);
        }
        return _buildStatCard(title, val, icon, color, onTap);
      },
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                const SizedBox(height: 8),
                Text(val, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: bgDark.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: twinGreen, size: 28),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Panel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Management Dashboard", style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: Colors.teal.shade800, radius: 18, child: const Text("A", style: TextStyle(color: Colors.white, fontSize: 12))),
            title: const Text("admin@gmail.com", style: TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: const Text("Administrator", style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false),
            child: const Row(
              children: [
                Icon(Icons.logout, color: Colors.blueGrey, size: 18),
                SizedBox(width: 12),
                Text("Sign out", style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            Navigator.pop(context);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: isSelected ? twinGreen : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.blueGrey, size: 20),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}