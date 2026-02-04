import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = Color(0xFF1DB98A);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        title: const Text("Payment Methods", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Saved Cards", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // Mock Card 1
            _buildCreditCard(
              brand: "VISA",
              number: "**** **** **** 4582",
              expiry: "09/27",
              color: Colors.blueGrey.shade900,
            ),
            
            const SizedBox(height: 30),
            const Text("Other Methods", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            _buildPaymentTile(Icons.account_balance_wallet, "UPI ID", "shinto@okaxis", twinGreen),
            _buildPaymentTile(Icons.account_balance, "Net Banking", "Linked Bank Account", twinGreen),
            
            const SizedBox(height: 40),
            
            // Add New Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logic to add new payment method
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Add New Method", 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: twinGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard({required String brand, required String number, required String expiry, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(brand, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              const Icon(Icons.contactless, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 30),
          Text(number, style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2)),
          const SizedBox(height: 25),
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("EXPIRY", style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text("09/27", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 40),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CARD HOLDER", style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text("SHINTO SEBASTIAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(IconData icon, String title, String subtitle, Color green) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: green.withOpacity(0.1),
          child: Icon(icon, color: green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}