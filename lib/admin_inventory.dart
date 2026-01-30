import 'package:flutter/material.dart';

class ManageInventoryPage extends StatelessWidget {
  const ManageInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F172A);
    const Color cardDark = Color(0xFF1E293B);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 850;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: isMobile 
            ? AppBar(
                title: const Text("Inventory", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: bgDark,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              )
            : null,
          body: Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile)
                  const Text("Inventory", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 32),
                
                _buildSearchBar(cardDark, "Search by product name or barcode..."),
                
                const SizedBox(height: 32),
                
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        // --- FIXED TABLE HEADER ---
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            children: [
                              const Expanded(
                                flex: 2, 
                                child: Text("Product", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))
                              ),
                              const Expanded(
                                child: Text(
                                  "Quantity", 
                                  textAlign: TextAlign.center, // FIXED: Moved outside TextStyle
                                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                )
                              ),
                              const Expanded(
                                child: Text(
                                  "Threshold", 
                                  textAlign: TextAlign.center, // FIXED: Moved outside TextStyle
                                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                )
                              ),
                              if (!isMobile)
                                const Expanded(
                                  child: Text(
                                    "Status", 
                                    textAlign: TextAlign.center, // FIXED: Moved outside TextStyle
                                    style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                  )
                                ),
                              const Expanded(
                                child: Text(
                                  "Actions", 
                                  textAlign: TextAlign.right, // FIXED: Moved outside TextStyle
                                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                )
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, color: Colors.blueGrey, size: 48),
                              SizedBox(height: 16),
                              Text("No inventory items found", style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                            ],
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
      constraints: const BoxConstraints(maxWidth: 500),
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