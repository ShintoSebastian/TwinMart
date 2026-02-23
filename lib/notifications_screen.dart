import 'package:flutter/material.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ✅ Notification Toggle States
  bool orderUpdates = true;
  bool promotionalOffers = false;
  bool priceAlerts = true;

  final Color twinGreen = const Color(0xFF1DB98A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwinMartTheme.bgLight,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -100,
            right: -80,
            size: 280,
            color: TwinMartTheme.brandGreen.withOpacity(0.15),
          ),
          TwinMartTheme.bgBlob(
            bottom: -50,
            left: -100,
            size: 300,
            color: TwinMartTheme.brandBlue.withOpacity(0.12),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Preference Settings", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        const SizedBox(height: 15),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildNotificationToggle(
                                title: "Order Updates",
                                subtitle: "Receive alerts about your order status",
                                value: orderUpdates,
                                onChanged: (val) => setState(() => orderUpdates = val),
                              ),
                              const Divider(height: 1),
                              _buildNotificationToggle(
                                title: "Promotions",
                                subtitle: "Special offers and discount codes",
                                value: promotionalOffers,
                                onChanged: (val) => setState(() => promotionalOffers = val),
                              ),
                              const Divider(height: 1),
                              _buildNotificationToggle(
                                title: "Price Alerts",
                                subtitle: "Get notified when favorites drop in price",
                                value: priceAlerts,
                                onChanged: (val) => setState(() => priceAlerts = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Center(
                          child: Text(
                            "TwinMart will only send essential updates if all notifications are turned off.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
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

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 10, right: 10, bottom: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: TwinMartTheme.darkText),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 5),
          TwinMartTheme.brandLogo(size: 20),
          const SizedBox(width: 8),
          TwinMartTheme.brandText(fontSize: 22),
          const Spacer(),
          const Text("Settings",
              style: TextStyle(
                  color: TwinMartTheme.darkText, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: twinGreen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
    );
  }
}