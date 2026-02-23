import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageReportsPage extends StatelessWidget {
  const ManageReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F172A);
    const Color cardDark = Color(0xFF1E293B);
    const Color twinGreen = Color(0xFF10B981);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Detect if we are in Mobile preview
        bool isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: isMobile 
            ? AppBar(
                title: const Text("Reports", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: bgDark,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              )
            : null,
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 32.0, vertical: isMobile ? 16.0 : 32.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile)
                    const Text("Reports", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 32),
                  
                  // --- TOP BAR: FILTER & EXPORT ---
                  isMobile 
                    ? Column(
                        children: [
                          _buildFilterDropdown(),
                          const SizedBox(height: 16),
                          _buildExportButton(twinGreen, true),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFilterDropdown(),
                          _buildExportButton(twinGreen, false),
                        ],
                      ),
                  
                  const SizedBox(height: 32),
                  
                  // --- STAT CARDS GRID ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                    builder: (context, snapshot) {
                      double totalRevenue = 0;
                      int transactions = 0;
                      double avgOrderValue = 0;

                      if (snapshot.hasData) {
                        transactions = snapshot.data!.docs.length;
                        for (var doc in snapshot.data!.docs) {
                          totalRevenue += (doc['totalAmount'] ?? 0).toDouble();
                        }
                        if (transactions > 0) {
                          avgOrderValue = totalRevenue / transactions;
                        }
                      }

                      return isMobile 
                        ? Column(
                            children: [
                              _buildStatCard("Total Revenue", "₹${totalRevenue.toInt()}", Icons.attach_money, Colors.green.withOpacity(0.1), Colors.green),
                              const SizedBox(height: 16),
                              _buildStatCard("Transactions", transactions.toString(), Icons.receipt_long, Colors.blue.withOpacity(0.1), Colors.blue),
                              const SizedBox(height: 16),
                              _buildStatCard("Avg. Order Value", "₹${avgOrderValue.toInt()}", Icons.trending_up, Colors.purple.withOpacity(0.1), Colors.purple),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _buildStatCard("Total Revenue", "₹${totalRevenue.toInt()}", Icons.attach_money, Colors.green.withOpacity(0.1), Colors.green)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildStatCard("Transactions", transactions.toString(), Icons.receipt_long, Colors.blue.withOpacity(0.1), Colors.blue)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildStatCard("Avg. Order Value", "₹${avgOrderValue.toInt()}", Icons.trending_up, Colors.purple.withOpacity(0.1), Colors.purple)),
                            ],
                          );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  // --- UI ATOM COMPONENTS ---

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: "Last 7 days",
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: ["Last 7 days", "Last 30 days", "Last 90 days", "Last year"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {},
        ),
      ),
    );
  }

  Widget _buildExportButton(Color twinGreen, bool isFullWidth) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF22D3EE)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 18),
        label: const Text("Export CSV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconBg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.blueGrey, fontSize: 14, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}