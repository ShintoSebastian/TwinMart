import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTransactionsPage extends StatelessWidget {
  const ManageTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F172A);
    const Color cardDark = Color(0xFF1E293B);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Detect if we are in Mobile preview to adjust layout
        bool isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: Colors.transparent, // Shell handles the dark background
          appBar: isMobile 
            ? AppBar(
                title: const Text("Transactions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: bgDark,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              )
            : null,
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 32.0, vertical: isMobile ? 16.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile)
                  const Text(
                    "Transactions", 
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                  ),
                
                const SizedBox(height: 32),
                
                // --- SEARCH BAR ---
                _buildSearchBar(cardDark, "Search transactions..."),
                
                const SizedBox(height: 32),
                
                // --- TRANSACTION TABLE ---
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Padding(
                          padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text("ID", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13))
                              ),
                              const Expanded(
                                child: Text(
                                  "Date", 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13),
                                )
                              ),
                              const Expanded(
                                child: Text(
                                  "Amount", 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13),
                                )
                              ),
                              if (!isMobile)
                                const Expanded(
                                  child: Text(
                                    "Status", 
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13),
                                  )
                                ),
                              const Expanded(
                                child: Text(
                                  "Actions", 
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13),
                                )
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        
                        // Dynamic Firestore Stream
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                              final docs = snapshot.data!.docs;
                              
                              if (docs.isEmpty) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.receipt_long_outlined, color: Colors.blueGrey, size: 48),
                                      SizedBox(height: 16),
                                      Text("No transactions found", style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                                    ],
                                  ),
                                );
                              }

                              return ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: docs.length,
                                separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data() as Map<String, dynamic>;
                                  final String docId = docs[index].id;
                                  final DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
                                  final String dateStr = date != null ? "${date.day}/${date.month}/${date.year}" : "--";
                                  
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 24.0, vertical: 16.0),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(docId.substring(0, 10) + "...", style: const TextStyle(color: Colors.white70, fontSize: 12))),
                                        Expanded(child: Text(dateStr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                                        Expanded(child: Text("₹${(data['totalAmount'] ?? 0).toInt()}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                        if (!isMobile)
                                          Expanded(
                                            child: Center(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                                child: const Text("Success", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: IconButton(
                                              icon: const Icon(Icons.open_in_new_rounded, color: Colors.blueGrey, size: 18),
                                              onPressed: () {
                                                // TODO: Show transaction details dialog
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSearchBar(Color cardDark, String hint) {
    return Container(
      height: 50,
      constraints: const BoxConstraints(maxWidth: 500), // Better for Web view
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.blueGrey, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}