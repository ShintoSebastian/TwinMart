import 'package:flutter/material.dart';

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
  final Color bgLight = const Color(0xFFF4F9F8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text("Notifications", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Preference Settings", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 15),
            
            // ✅ White Container matching the "Settings" card UI
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