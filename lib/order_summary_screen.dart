import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'payment_methods_screen.dart';
import 'saved_addresses_screen.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;

class OrderSummaryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const OrderSummaryScreen({
    super.key,
    required this.items,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final Color twinGreen = TwinMartTheme.brandGreen;
  final Color twinTeal = TwinMartTheme.brandTeal;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userId = user?.uid ?? "";
    
    double totalPrice = 0;
    double originalTotalPrice = 0;
    
    for (var item in widget.items) {
      final double p = (item['price'] ?? 0).toDouble();
      final double op = (item['originalPrice'] ?? p).toDouble();
      final int q = (item['quantity'] ?? 1);
      totalPrice += p * q;
      originalTotalPrice += op * q;
    }
    
    final double savings = originalTotalPrice - totalPrice;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TwinMartTheme.brandLogo(size: 18, context: context),
            const SizedBox(width: 8),
            TwinMartTheme.brandText(fontSize: 18, context: context),
            const SizedBox(width: 10),
            Text("| Summary", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14)),
          ],
        ),
      ),
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -100,
            left: -80,
            size: 280,
            color: twinGreen.withOpacity(0.15),
          ),
          TwinMartTheme.bgBlob(
            bottom: 150,
            right: -100,
            size: 320,
            color: TwinMartTheme.brandBlue.withOpacity(0.1),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Delivery Address Section
                  _buildAddressSection(userId),
                  const SizedBox(height: 15),

                  // Product Details Section
                  _buildProductsListSection(),
                  const SizedBox(height: 15),

                  // Delivery Info
                  _buildDeliveryInfo(),
                  const SizedBox(height: 15),

                  // Extra Info
                  _buildExtraInfo(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          
          // Bottom Continue Bar
          _buildBottomAction(totalPrice, savings),
        ],
      ),
    );
  }

  Widget _buildAddressSection(String userId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Delivery Address",
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: twinGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Change",
                    style: TextStyle(color: twinGreen, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) return const SizedBox.shrink();
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              final String userName = userData?['name'] ?? "User";
              final String userPhone = userData?['phone'] ?? "";

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('userAddresses')
                    .orderBy('isDefault', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, addressSnapshot) {
                  String fullAddress = "Please add a delivery address";
                  String addressType = "HOME";

                  if (addressSnapshot.hasData && addressSnapshot.data!.docs.isNotEmpty) {
                    final addrData = addressSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    fullAddress = addrData['fullAddress'] ?? "";
                    addressType = (addrData['type'] ?? "HOME").toString().toUpperCase();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(addressType == "HOME" ? Icons.home_rounded : Icons.work_rounded, size: 16, color: twinGreen),
                          const SizedBox(width: 8),
                          Text(
                            userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fullAddress,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7), 
                          fontSize: 13, 
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userPhone,
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsListSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          ...widget.items.map((item) => _buildProductItem(item)).toList(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    final double price = (item['price'] ?? 0).toDouble();
    final double originalPrice = (item['originalPrice'] ?? price).toDouble();
    final int itemQty = item['quantity'] ?? 1;
    
    int discount = 0;
    if (originalPrice > price) {
      discount = (((originalPrice - price) / originalPrice) * 100).toInt();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty)
              ? Image.network(
                  item['imageUrl'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Text("🛍️", style: TextStyle(fontSize: 24))),
                )
              : const Center(child: Text("🛍️", style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 15),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? "Product Name",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Qty: $itemQty",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    Text(
                      "₹${(price * itemQty).toInt()}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                        color: twinGreen,
                      ),
                    ),
                  ],
                ),
                if (originalPrice > price)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "₹${(originalPrice * itemQty).toInt()}",
                          style: const TextStyle(
                            color: Colors.grey, 
                            decoration: TextDecoration.lineThrough, 
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "$discount% OFF",
                          style: const TextStyle(
                            color: Colors.orange, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: twinGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: twinGreen.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: twinGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_shipping_rounded, color: twinGreen, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Standard Delivery",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: twinGreen),
                ),
                const SizedBox(height: 2),
                Text(
                  "Expected by Wed, Mar 18",
                  style: TextStyle(color: twinGreen.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          const Text(
            "FREE",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_outline_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("E-Receipt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("Sent to your registered email", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildBottomAction(double totalPrice, double savings) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (savings > 0)
                    Text(
                      "YOU SAVE ₹${savings.toInt()}",
                      style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        "₹${totalPrice.toInt()}",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.titleLarge?.color),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            SizedBox(
              height: 60,
              width: 160,
              child: ElevatedButton(
                onPressed: () async {
                  final bool? success = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentMethodsScreen(
                        amount: totalPrice,
                        items: widget.items,
                        isOnlineOrder: true,
                      ),
                    ),
                  );

                  if (success == true) {
                    if (context.mounted) Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: twinGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text(
                  "Payment",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
