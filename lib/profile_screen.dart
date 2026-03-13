import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'edit_profile_screen.dart';
import 'order_history_screen.dart';
import 'saved_addresses_screen.dart';
import 'wishlist_screen.dart'; 
import 'notifications_screen.dart'; 
import 'help_support_screen.dart'; 
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'package:twinmart_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
class ProfileScreen extends StatefulWidget {
  final VoidCallback onBackToDashboard; 

  const ProfileScreen({super.key, required this.onBackToDashboard});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color twinGreen = TwinMartTheme.brandGreen;
  final Color twinTeal = TwinMartTheme.brandTeal;
  final Color bgLight = TwinMartTheme.bgLight;

  String userName = "User";
  String userPhone = "";
  String userEmail = "";
  String userInitial = "U";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && mounted) {
      setState(() {
        userName = doc['name'] ?? "User";
        userPhone = doc['phone'] ?? "";
        userEmail = doc['email'] ?? user.email ?? "";
        userInitial =
            userName.isNotEmpty ? userName[0].toUpperCase() : "U";
      });
    }
  }

  // NEW: Password Change Logic (Sends Email)
  Future<void> _handleChangePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Reset link sent to ${user.email}"),
              backgroundColor: twinGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to send reset link. Try again later.")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -120,
            right: -100,
            size: 320,
            color: TwinMartTheme.brandGreen.withOpacity(0.2),
          ),
          TwinMartTheme.bgBlob(
            bottom: 100,
            left: -60,
            size: 280,
            color: TwinMartTheme.brandBlue.withOpacity(0.18),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(),
                    const SizedBox(height: 20),
                    _buildProfileCard(),
                    const SizedBox(height: 25),
                    _buildStatsRow(),
                    const SizedBox(height: 30),
                    Text(
                      "Settings",
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildSettingsCard(),
                    const SizedBox(height: 25),
                    _buildSignOutButton(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  widget.onBackToDashboard();
                }
              }, 
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Icon(Icons.arrow_back_ios_new, size: 18, color: Theme.of(context).iconTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
              ),
            ),
            const SizedBox(width: 12),
            TwinMartTheme.brandLogo(size: 18, context: context),
            const SizedBox(width: 10),
            TwinMartTheme.brandText(fontSize: 18, context: context),
          ],
        ),
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: twinGreen,
              child: Text(
                userInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [twinGreen, twinTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: twinGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white24,
            child: Text(
              userInitial,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            userPhone.isNotEmpty ? userPhone : "No phone number",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('budget')
          .doc('settings')
          .snapshots(),
      builder: (context, budgetSnapshot) {
        double savings = 0.0;
        if (budgetSnapshot.hasData && budgetSnapshot.data!.exists) {
          final data = budgetSnapshot.data!.data() as Map<String, dynamic>?;
          savings = (data?['total_savings'] ?? 0.0).toDouble();
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, ordersSnapshot) {
            int totalOrders = 0;
            double totalSpent = 0.0;

            if (ordersSnapshot.hasData) {
              totalOrders = ordersSnapshot.data!.docs.length;
              for (var doc in ordersSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalSpent += (data['totalAmount'] ?? 0.0).toDouble();
              }
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statCard("Total Orders", totalOrders.toString()),
                _statCard("Total Spent", "₹${totalSpent.toInt()}"),
                _statCard("Saved", "₹${savings.toInt()}"),
              ],
            );
          },
        );
      }
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: twinGreen,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          _settingsTile(
            icon: Icons.edit,
            title: "Edit Profile",
            subtitle: "Update your personal details",
            onTap: () async {
              // Corrected: Now passing currentEmail and awaiting the result
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    currentName: userName,
                    currentPhone: userPhone,
                    currentEmail: userEmail,
                  ),
                ),
              );
              // Refresh the data when returning from the edit screen
              _fetchUserData();
            },
          ),
          _settingsTile(
            icon: Icons.shopping_bag_outlined,
            title: "Order History",
            subtitle: "View past orders",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrderHistoryScreen()),
              );
            },
          ),
          _settingsTile(
            icon: Icons.favorite_border,
            title: "My Wishlist",
            subtitle: "Items you've saved for later",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistScreen()),
              );
            },
          ),
          // ADDED CHANGE PASSWORD TILE
          _settingsTile(
            icon: Icons.lock_reset_outlined,
            title: "Change Password",
            subtitle: "Send a reset link to your email",
            onTap: _handleChangePassword,
          ),

          _settingsTile(
            icon: Icons.location_on_outlined,
            title: "Saved Addresses",
            subtitle: "Delivery locations",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SavedAddressesScreen()),
              );
            },
          ),
          _settingsTile(
            icon: Icons.help_outline,
            title: "Help & Support",
            subtitle: "FAQs and contact information",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isDark = themeProvider.isDarkMode;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.amber,
                  ),
                ),
                title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(themeProvider.themeMode == ThemeMode.system ? "Follows System" : (isDark ? "On" : "Off")),
                trailing: Switch(
                  value: isDark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                  activeColor: twinGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: twinGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: twinGreen),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _buildSignOutButton() {
    return OutlinedButton(
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        side: BorderSide(color: twinGreen),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        "Sign Out",
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }
}