import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'package:twinmart_app/invoice_service.dart';
import 'product_details_screen.dart';
import 'dart:ui' as ui;

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _selectedTab = 0; // 0: Online, 1: Offline

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -120,
            left: -100,
            size: 320,
            color: TwinMartTheme.brandGreen.withOpacity(0.2),
          ),
          TwinMartTheme.bgBlob(
            bottom: -80,
            right: -100,
            size: 300,
            color: TwinMartTheme.brandBlue.withOpacity(0.15),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: SafeArea(
              child: userId.isEmpty
                  ? Column(children: [
                      _buildAppBar(context, []),
                      const Expanded(child: Center(child: Text("Please login to view orders")))
                    ])
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('userId', isEqualTo: userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Column(children: [
                            _buildAppBar(context, []),
                            Expanded(child: _buildErrorState("Error: ${snapshot.error}"))
                          ]);
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Column(children: [
                            _buildAppBar(context, []),
                            const Expanded(child: Center(child: CircularProgressIndicator(color: TwinMartTheme.brandGreen)))
                          ]);
                        }

                        final allDocs = snapshot.data?.docs ?? [];
                        
                        // Filter & Sort
                        final List<DocumentSnapshot> filteredDocs = allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final type = data['type'] ?? 'online';
                          return _selectedTab == 0 ? (type == 'online') : (type == 'offline');
                        }).toList();

                        filteredDocs.sort((a, b) {
                          final t1 = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                          final t2 = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                          if (t1 == null) return 1;
                          if (t2 == null) return -1;
                          return t2.compareTo(t1);
                        });

                        return Column(
                          children: [
                            _buildAppBar(context, allDocs), // AppBar shows summary of ALL orders
                            _buildTabSwitcher(),
                            Expanded(
                              child: filteredDocs.isEmpty 
                                ? _buildEmptyState(_selectedTab == 0 ? "No online orders" : "No offline purchases")
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: filteredDocs.length,
                                    itemBuilder: (context, index) => _buildOrderCard(filteredDocs[index]),
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          _tabItem(0, "Online Orders", Icons.language_outlined),
          _tabItem(1, "Offline Buy", Icons.store_outlined),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String title, IconData icon) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? TwinMartTheme.brandGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, List<DocumentSnapshot> orders) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05), blurRadius: 10)],
              ),
              child: Icon(Icons.arrow_back_ios_new, size: 18, color: Theme.of(context).iconTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          TwinMartTheme.brandLogo(size: 20, context: context),
          const SizedBox(width: 8),
          TwinMartTheme.brandText(fontSize: 22, context: context),
          const Spacer(),
          Text(
            "History",
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodySmall?.color
            ),
          ),
          GestureDetector(
            onTap: orders.isEmpty ? null : () => _showSummaryDialog(context, orders),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100),
                boxShadow: [
                  if (orders.isNotEmpty) 
                    BoxShadow(color: TwinMartTheme.brandGreen.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)
                ]
              ),
              child: const Icon(Icons.receipt_long_outlined, color: TwinMartTheme.brandGreen, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String? title) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: TwinMartTheme.brandGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined, size: 80, color: TwinMartTheme.brandGreen.withOpacity(0.3)),
            ),
            const SizedBox(height: 24),
             Text(
              title ?? "No orders yet", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)
            ),
            const SizedBox(height: 8),
            const Text(
              "Your transaction history will appear here.", 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String status = data['status'] ?? 'Completed';
    final DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
    final String dateStr = date != null ? "${date.day} ${_getMonth(date.month)} ${date.year}" : "Recently";
    final double amount = (data['totalAmount'] ?? 0.0).toDouble();
    final int itemsCount = data['itemsCount'] ?? 0;
    final String paymentMethod = data['paymentMethod'] ?? 'Paid';

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _resolveOrderItems(doc.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonCard();
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const SizedBox.shrink(); // Hide if no transaction data found
        }

        final firstItem = items.first;
        String displayName = firstItem['productName'] ?? "Order #${doc.id.length > 8 ? doc.id.substring(doc.id.length - 8).toUpperCase() : doc.id.toUpperCase()}";
        if (items.length > 1) displayName += "...";

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // In future: Redirect to a detailed order page
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.5,
                                      child: Text(
                                        displayName, 
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status, 
                                        style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold)
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 15),
                                // Display Multiple Product Images
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: items.map((item) {
                                      final img = item['productImage'] ?? "🛒";
                                      final int qty = (item['quantity'] ?? 1) as int;
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 15),
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 60,
                                              width: 60,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade200),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: (img is String && img.startsWith('http'))
                                                  ? Image.network(
                                                      img,
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 20),
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        img.toString().isEmpty ? "🛒" : img.toString(),
                                                        style: const TextStyle(fontSize: 24)
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              "$qty",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: Theme.of(context).textTheme.bodyLarge?.color
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Items", style: TextStyle(color: Colors.grey, fontSize: 11)),
                              Text("$itemsCount Products", style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Payment", style: TextStyle(color: Colors.grey, fontSize: 11)),
                              Text(paymentMethod.split(' ')[0], style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          // Download Invoice Button
                          GestureDetector(
                            onTap: () {
                              final user = FirebaseAuth.instance.currentUser;
                              // Build items list from resolved transaction data
                              final invoiceItems = items.map((txItem) => {
                                'name': txItem['productName'] ?? 'Item',
                                'quantity': txItem['quantity'] ?? 1,
                                'price': (txItem['price'] ?? 0).toDouble(),
                              }).toList();
                              InvoiceService.previewInvoice(
                                context,
                                orderId: doc.id,
                                totalAmount: amount,
                                items: invoiceItems,
                                paymentMethod: paymentMethod,
                                customerName: user?.displayName ?? 'Customer',
                                customerEmail: user?.email ?? '',
                                orderDate: date,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: TwinMartTheme.brandGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: TwinMartTheme.brandGreen, size: 20),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("Amount", style: TextStyle(color: Colors.grey, fontSize: 11)),
                              Text("₹${amount.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: TwinMartTheme.brandGreen)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _resolveOrderItems(String orderId) async {
    final txSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('transactions')
        .where('transactionId', isEqualTo: orderId)
        .get();

    List<Map<String, dynamic>> resolved = [];
    for (var txDoc in txSnap.docs) {
      final Map<String, dynamic> txData = txDoc.data();
      if (txData['productImage'] != null) {
        resolved.add(txData);
      } else {
        // Fallback fetch for older orders missing images in transaction
        final pDoc = await _getFallbackProductData(txData['productId'], txData['productName'] ?? "");
        if (pDoc != null) {
          final pData = pDoc.data() as Map<String, dynamic>;
          resolved.add({
            ...txData,
            'productImage': pData['imageUrl'],
            'productName': pData['name'],
          });
        } else {
          resolved.add(txData);
        }
      }
    }
    return resolved;
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('comp')) return Colors.green;
    if (status.toLowerCase().contains('pend')) return Colors.orange;
    if (status.toLowerCase().contains('canc')) return Colors.red;
    return Colors.blue;
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showSummaryDialog(BuildContext context, List<DocumentSnapshot> orders) {
    double totalSpent = 0;
    int totalItems = 0;
    int onlineCount = 0;
    int offlineCount = 0;

    for (var doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      totalSpent += (data['totalAmount'] ?? 0.0).toDouble();
      totalItems += (data['itemsCount'] ?? 0) as int;
      if (data['type'] == 'online') {
        onlineCount++;
      } else {
        offlineCount++;
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: TwinMartTheme.brandGreen.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.analytics_outlined, color: TwinMartTheme.brandGreen, size: 32),
                  ),
                  const SizedBox(height: 20),
                  const Text("Purchase Summary", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("Analyzing ${orders.length} orders", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  _summaryRow("Total Expenditure", "₹${totalSpent.toInt()}", TwinMartTheme.brandGreen),
                  const SizedBox(height: 15),
                  _summaryRow("Items Purchased", "$totalItems Items", Colors.blue),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _miniStat("Online", onlineCount, Colors.purple)),
                      const SizedBox(width: 15),
                      Expanded(child: _miniStat("Offline", offlineCount, Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Positioned(
              top: 15,
              right: 15,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.grey, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.1))
      ),
      child: Column(
        children: [
          Text(value.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<DocumentSnapshot?> _getFallbackProductData(String? productId, String productName) async {
    try {
      // 1. Try by Product ID if available
      if (productId != null && productId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
        if (doc.exists) return doc;
      }

      // 2. Try by Exact Name
      final nameQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: productName)
          .limit(1)
          .get();
      
      if (nameQuery.docs.isNotEmpty) return nameQuery.docs.first;

      // 3. Try partial name search if it's not a generic "Order #..."
      if (!productName.startsWith("Order #")) {
         final searchResult = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: productName)
          .where('name', isLessThanOrEqualTo: '$productName\uf8ff')
          .limit(1)
          .get();
        if (searchResult.docs.isNotEmpty) return searchResult.docs.first;
      }
    } catch (e) {
      debugPrint("Fallback fetch error: $e");
    }
    return null;
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: TwinMartTheme.brandGreen)),
    );
  }
}
