import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageInventoryPage extends StatelessWidget {
  const ManageInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F172A);
    const Color cardDark = Color(0xFF1E293B);
    const Color twinGreen = Color(0xFF10B981);

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
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 32.0, vertical: isMobile ? 16.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile)
                  const Text("Inventory", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 32),
                
                Center(child: _buildSearchBar(cardDark, "Search products...")),
                
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
                        // --- TABLE HEADER ---
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 24.0, vertical: isMobile ? 12.0 : 24.0),
                          child: Row(
                            mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                            children: [
                              if (isMobile)
                                SizedBox(width: 130, child: Text("Product", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis))
                              else
                                const Expanded(flex: 2, child: Text("Product", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13))),
                              
                              if (isMobile) const SizedBox(width: 4),
                              
                              SizedBox(
                                width: isMobile ? 35 : 100, 
                                child: Text(
                                  "Qty", 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13),
                                )
                              ),
                              
                              if (isMobile) const SizedBox(width: 4),
                              
                              SizedBox(
                                width: isMobile ? 35 : 100, 
                                child: Text(
                                  "Min", 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13),
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
                              
                              if (isMobile) const SizedBox(width: 4),
                              
                              SizedBox(
                                width: isMobile ? 65 : 100, 
                                child: Text(
                                  isMobile ? "" : "Actions", 
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13),
                                )
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('products').snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: twinGreen));
                              final docs = snapshot.data!.docs;

                              if (docs.isEmpty) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2_outlined, color: Colors.blueGrey, size: 48),
                                      SizedBox(height: 16),
                                      Text("No inventory items found", style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
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
                                   
                                   int stock = (data['stock'] ?? 0);
                                   int threshold = data['threshold'] ?? 10;
                                   
                                   Color statusColor = Colors.green;
                                   String statusText = "Good";
                                   if (stock <= 0) {
                                     statusColor = Colors.red;
                                     statusText = "Critical";
                                   } else if (stock <= threshold) {
                                     statusColor = Colors.orange;
                                     statusText = "Low";
                                   }

                                   return Padding(
                                     padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 24.0, vertical: 16.0),
                                     child: Row(
                                       mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                                       children: [
                                         if (isMobile)
                                           SizedBox(
                                             width: 130,
                                             child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 Text(
                                                   data['name'] ?? "", 
                                                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), 
                                                   maxLines: 1, 
                                                   overflow: TextOverflow.ellipsis
                                                 ),
                                                 Text(
                                                   data['category'] ?? "General", 
                                                   style: const TextStyle(color: Colors.blueGrey, fontSize: 8),
                                                   maxLines: 1,
                                                   overflow: TextOverflow.ellipsis,
                                                 ),
                                               ],
                                             ),
                                           )
                                         else
                                           Expanded(
                                             flex: isMobile ? 3 : 2,
                                             child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 Text(
                                                   data['name'] ?? "", 
                                                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 15), 
                                                   maxLines: 1, 
                                                   overflow: TextOverflow.ellipsis
                                                 ),
                                                 Text(
                                                   data['category'] ?? "General", 
                                                   style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                                                   maxLines: 1,
                                                   overflow: TextOverflow.ellipsis,
                                                 ),
                                               ],
                                             ),
                                           ),
                                         
                                         if (isMobile) const SizedBox(width: 4),
                                         
                                         SizedBox(
                                           width: isMobile ? 35 : 100,
                                           child: Text(
                                             stock.toString(), 
                                             textAlign: TextAlign.center, 
                                             style: TextStyle(color: twinGreen, fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 15)
                                           ),
                                         ),
                                         
                                         if (isMobile) const SizedBox(width: 4),
                                         
                                         SizedBox(
                                           width: isMobile ? 35 : 100,
                                           child: Text(
                                             threshold.toString(), 
                                             textAlign: TextAlign.center, 
                                             style: TextStyle(color: Colors.blueGrey, fontSize: isMobile ? 10 : 13)
                                           ),
                                         ),
                                         
                                         if (!isMobile)
                                           Expanded(
                                             child: Center(
                                               child: Container(
                                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                 decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                                 child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                               ),
                                             ),
                                           ),
                                         
                                         if (isMobile) const SizedBox(width: 4),
                                         
                                         SizedBox(
                                           width: isMobile ? 65 : 100,
                                           child: Row(
                                             mainAxisAlignment: MainAxisAlignment.end,
                                             children: [
                                               IconButton(
                                                 padding: EdgeInsets.zero,
                                                 constraints: BoxConstraints(minWidth: isMobile ? 24 : 40, minHeight: isMobile ? 32 : 40),
                                                 icon: Icon(Icons.remove_circle_outline, color: Colors.blueGrey, size: isMobile ? 16 : 22),
                                                 onPressed: () {
                                                   FirebaseFirestore.instance.collection('products').doc(docId).update({'stock': stock - 1});
                                                 },
                                               ),
                                               IconButton(
                                                 padding: EdgeInsets.zero,
                                                 constraints: BoxConstraints(minWidth: isMobile ? 24 : 40, minHeight: isMobile ? 32 : 40),
                                                 icon: Icon(Icons.add_circle_outline, color: const Color(0xFF10B981), size: isMobile ? 16 : 22),
                                                 onPressed: () {
                                                   FirebaseFirestore.instance.collection('products').doc(docId).update({'stock': stock + 1});
                                                 },
                                               ),
                                             ],
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

