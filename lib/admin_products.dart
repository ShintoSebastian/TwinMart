import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageProductsPage extends StatefulWidget {
  const ManageProductsPage({super.key});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  // ---------- ADD / EDIT DIALOG ----------
  void _showProductDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final nameController = TextEditingController(text: doc != null ? doc['name'] : "");
    final descController = TextEditingController(text: doc != null ? doc['description'] : "");
    final aboutController = TextEditingController(text: doc != null && (doc.data() as Map).containsKey('about') ? doc['about'] : "");
    final priceController = TextEditingController(text: doc != null ? doc['price'].toString() : "");
    final originalPriceController = TextEditingController(
      text: doc != null && (doc.data() as Map).containsKey('originalPrice') ? doc['originalPrice'].toString() : ""
    );
    final offerLineController = TextEditingController(
      text: doc != null && (doc.data() as Map).containsKey('offerLine') ? doc['offerLine'] : ""
    );
    final urlController = TextEditingController(text: doc != null ? doc['imageUrl'] : "");
    final imagesController = TextEditingController(
      text: (doc != null && (doc.data() as Map).containsKey('images')) 
          ? (doc['images'] as List).join(', ') 
          : ""
    );
    
    // Convert specifications map to string "Key: Value" per line
    String specsString = "";
    if (doc != null && (doc.data() as Map).containsKey('specifications')) {
      final Map<String, dynamic> specs = doc['specifications'];
      specsString = specs.entries.map((e) => "${e.key}: ${e.value}").join('\n');
    }
    final specsController = TextEditingController(text: specsString);
    
    // ✅ NEW: Controllers for Inventory
    final barcodeController = TextEditingController(
      text: doc != null && (doc.data() as Map).containsKey('barcode') ? doc['barcode'] : ""
    );
    final stockController = TextEditingController(
      text: doc != null && (doc.data() as Map).containsKey('stock') ? doc['stock'].toString() : "50"
    );
    final thresholdController = TextEditingController(
      text: doc != null && (doc.data() as Map).containsKey('threshold') ? doc['threshold'].toString() : "10"
    );
    bool isOffline = doc != null && (doc.data() as Map).containsKey('offline') ? doc['offline'] : false;

    String selectedCategory = doc != null ? doc['category'] : "Select category";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                doc == null ? "Add New Product" : "Edit Product",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Product Image URL"),
                      _buildDialogTextField("Paste direct image link here", urlController),
                      _buildLabel("Name"),
                      _buildDialogTextField("Enter product name", nameController, isGreenBorder: true),
                      
                      // ✅ NEW: Barcode Field for Scanner
                      _buildLabel("Barcode (for Offline Store)"),
                      _buildDialogTextField("e.g. 1001", barcodeController, isGreenBorder: true),

                      _buildLabel("Inventory Stock"),
                      Row(
                        children: [
                          Expanded(child: _buildDialogTextField("Current Qty", stockController)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDialogTextField("Min Threshold", thresholdController)),
                        ],
                      ),

                      _buildLabel("Short Subtitle / Quantity"),
                      _buildDialogTextField("e.g. 1 kg or 8-core CPU", descController),
                      _buildLabel("About this item"),
                      _buildDialogTextField("Enter points line by line (one per line)", aboutController, maxLines: 5),
                      _buildLabel("Pricing (₹)"),
                      Row(
                        children: [
                          Expanded(child: _buildDialogTextField("Discounted Price", priceController, isGreenBorder: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDialogTextField("Original Price", originalPriceController)),
                        ],
                      ),
                      
                      _buildLabel("Offer Hint (e.g. 'Up to 10% Off' or 'Best Seller')"),
                      _buildDialogTextField("Catchy offer line", offerLineController),
                      
                      _buildLabel("Additional Image URLs (comma separated)"),
                      _buildDialogTextField("url1, url2, ...", imagesController, maxLines: 2),

                      _buildLabel("Specifications (Key: Value per line)"),
                      _buildDialogTextField("Brand: Apple\nColor: Silver", specsController, maxLines: 5),
                      
                      // ✅ NEW: Offline Toggle
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text("Available for Offline Scan", style: TextStyle(color: Colors.white, fontSize: 14)),
                            ),
                            Switch(
                              value: isOffline,
                              activeColor: const Color(0xFF10B981),
                              onChanged: (val) => setDialogState(() => isOffline = val),
                            ),
                          ],
                        ),
                      ),

                      _buildLabel("Category"),
                      _buildCategoryDropdown(
                        currentValue: selectedCategory,
                        onChanged: (val) => setDialogState(() => selectedCategory = val!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                // ✅ Pass new parameters to submit button
                _buildDialogSubmitButton(
                  context, 
                  nameController, 
                  descController, 
                  priceController, 
                   urlController, 
                   imagesController,
                   specsController,
                   aboutController, // ✅ NEW
                   barcodeController, 
                   stockController,
                   thresholdController,
                   originalPriceController,
                   offerLineController,
                   isOffline, 
                   selectedCategory, 
                   docId: doc?.id
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- UPDATED SUBMIT ----------
  Widget _buildDialogSubmitButton(
      BuildContext context, 
      TextEditingController name, 
      TextEditingController desc, 
       TextEditingController price, 
       TextEditingController url, 
       TextEditingController images,
       TextEditingController specs,
       TextEditingController about, // ✅ NEW
       TextEditingController barcode, 
       TextEditingController stock,
       TextEditingController threshold,
       TextEditingController originalPrice,
       TextEditingController offerLine,
       bool isOffline, 
       String category, 
       {String? docId}) {
    return GestureDetector(
      onTap: () async {
        if (name.text.isEmpty || category == "Select category") return;
        
         // ✅ Parse images list
         List<String> imagesList = [];
         if (images.text.trim().isNotEmpty) {
           imagesList = images.text.split(',').map((e) => e.trim()).toList();
         }

         // ✅ Parse specifications map
         Map<String, String> specsMap = {};
         if (specs.text.trim().isNotEmpty) {
           final lines = specs.text.split('\n');
           for (var line in lines) {
             if (line.contains(':')) {
               final parts = line.split(':');
               specsMap[parts[0].trim()] = parts[1].trim();
             }
           }
         }

         // ✅ Updated data map with offline fields, images and specs
         final data = {
           'name': name.text.trim(),
           'description': desc.text.trim(),
           'about': about.text.trim(), // ✅ NEW
           'price': double.tryParse(price.text) ?? 0.0,
           'category': category,
           'imageUrl': url.text.trim(),
           'images': imagesList,
           'specifications': specsMap,
           'barcode': barcode.text.trim(), 
           'stock': int.tryParse(stock.text) ?? 50,
           'threshold': int.tryParse(threshold.text) ?? 10,
           'originalPrice': double.tryParse(originalPrice.text) ?? 0.0,
           'offerLine': offerLine.text.trim(),
           'offline': isOffline,           
           'timestamp': FieldValue.serverTimestamp(),
         };

        if (docId == null) {
          await FirebaseFirestore.instance.collection('products').add(data);
        } else {
          await FirebaseFirestore.instance.collection('products').doc(docId).update(data);
        }
        if (context.mounted) Navigator.pop(context);
      },
      child: _buildGradientButton(context, docId == null ? "Create" : "Update"),
    );
  }

  // ---------- MAIN UI (UNCHANGED) ----------
  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F172A);
    const Color cardDark = Color(0xFF1E293B);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 750;

        return Scaffold(
          backgroundColor: Colors.transparent, 
          appBar: isMobile 
            ? AppBar(
                title: const Text("Products", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  const Text("Products", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 32),
                
                isMobile 
                  ? Column(
                      children: [
                        _buildSearchBar(cardDark, "Search products..."),
                        const SizedBox(height: 16),
                        _buildMainAddButton(context, isMobile),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildSearchBar(cardDark, "Search products...")),
                        const SizedBox(width: 24),
                        _buildMainAddButton(context, isMobile),
                      ],
                    ),
                
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
                        Padding(
                          padding: EdgeInsets.all(isMobile ? 8.0 : 24.0),
                          child: Row(
                            children: [
                              Expanded(flex: isMobile ? 4 : 2, child: Text("Name", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Expanded(flex: isMobile ? 2 : 1, child: Text("Price", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              if (!isMobile) const Expanded(child: Text("Category", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Expanded(flex: isMobile ? 2 : 1, child: Text(isMobile ? "" : "Actions", textAlign: TextAlign.right, style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('products').orderBy('timestamp', descending: true).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                              final docs = snapshot.data!.docs;
                              return ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: docs.length,
                                separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                                itemBuilder: (context, index) {
                                  final doc = docs[index];
                                  final data = doc.data() as Map<String, dynamic>;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(flex: isMobile ? 4 : 2, child: Text(data['name'] ?? "", style: TextStyle(color: Colors.white, fontSize: isMobile ? 13 : 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        Expanded(flex: isMobile ? 2 : 1, child: Text("₹${data['price']}", style: TextStyle(color: Colors.white, fontSize: isMobile ? 13 : 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        if (!isMobile) Expanded(child: Text(data['category'] ?? "General", style: const TextStyle(color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        Expanded(
                                          flex: isMobile ? 2 : 1,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: Icon(Icons.edit_outlined, color: Colors.blueAccent, size: isMobile ? 18 : 20),
                                                onPressed: () => _showProductDialog(context, doc: doc),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: isMobile ? 18 : 20),
                                                onPressed: () => _showDeleteConfirmation(context, doc.id),
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
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Product", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to remove this item?", style: TextStyle(color: Colors.blueGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white))),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('products').doc(docId).delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
  );

  Widget _buildDialogTextField(String hint, TextEditingController controller, {int maxLines = 1, bool isGreenBorder = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(
            color: isGreenBorder ? const Color(0xFF10B981) : Colors.white10,
            width: isGreenBorder ? 2 : 1,
          )
        ),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
      ),
    );
  }

  Widget _buildSearchBar(Color cardDark, String hint) {
    return Container(
      height: 50,
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

  Widget _buildCategoryDropdown({required String currentValue, required Function(String?) onChanged}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        List<DropdownMenuItem<String>> items = [
          const DropdownMenuItem(value: "Select category", child: Text("Select category", style: TextStyle(color: Colors.blueGrey)))
        ];
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            items.add(DropdownMenuItem(value: doc['name'], child: Text(doc['name'], style: const TextStyle(color: Colors.white))));
          }
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.any((item) => item.value == currentValue) ? currentValue : "Select category",
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              items: items,
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainAddButton(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () => _showProductDialog(context),
      child: _buildGradientButton(context, "Add Product", isMobile: isMobile, hasIcon: true),
    );
  }

  Widget _buildGradientButton(BuildContext context, String text, {bool isMobile = false, bool hasIcon = false}) {
    return Container(
      width: isMobile ? double.infinity : null,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF22D3EE)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasIcon) const Icon(Icons.add, color: Colors.white, size: 20),
          if (hasIcon) const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}