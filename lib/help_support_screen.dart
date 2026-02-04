import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  final Color twinGreen = const Color(0xFF1DB98A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        title: const Text("Help & Support", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactCard(),
            const SizedBox(height: 30),
            const Text("Frequently Asked Questions", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildFaqList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: twinGreen,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: twinGreen.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Text("How can we help you?", 
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Our team is available 24/7 to assist you with your orders.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Logic to open WhatsApp or Email
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1DB98A)),
            label: const Text("Contact Live Support"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: twinGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFaqList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          _faqTile("How do I track my order?", "You can track your order in the 'Order History' section of your profile."),
          const Divider(height: 1),
          _faqTile("What is the return policy?", "Items can be returned within 7 days of delivery if they are in original condition."),
          const Divider(height: 1),
          _faqTile("How do I change my address?", "Go to 'Saved Addresses' in your profile settings to add or edit delivery locations."),
        ],
      ),
    );
  }

  Widget _faqTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Text(answer, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        )
      ],
    );
  }
}