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
    final priceController = TextEditingController(text: doc != null ? doc['price'].toString() : "");
    final urlController = TextEditingController(text: doc != null ? doc['imageUrl'] : "");

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
                  width: 450,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Product Image URL"),
                      _buildDialogTextField("Paste direct image link here", urlController),
                      _buildLabel("Name"),
                      _buildDialogTextField("Enter product name", nameController, isGreenBorder: true),
                      _buildLabel("Description"),
                      _buildDialogTextField("Enter description", descController, maxLines: 3),
                      _buildLabel("Price"),
                      _buildDialogTextField("0.00", priceController),
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
                _buildDialogSubmitButton(context, nameController, descController, priceController, urlController, selectedCategory, docId: doc?.id),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- SUBMIT ----------
  Widget _buildDialogSubmitButton(BuildContext context, TextEditingController name, TextEditingController desc, TextEditingController price, TextEditingController url, String category, {String? docId}) {
    return GestureDetector(
      onTap: () async {
        if (name.text.isEmpty || category == "Select category") return;
        final data = {
          'name': name.text,
          'description': desc.text,
          'price': double.tryParse(price.text) ?? 0.0,
          'category': category,
          'imageUrl': url.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        };
        if (docId == null) {
          await FirebaseFirestore.instance.collection('products').add(data);
        } else {
          await FirebaseFirestore.instance.collection('products').doc(docId).update(data);
        }
        if (context.mounted) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF22D3EE)]),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(docId == null ? "Create" : "Update", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ---------- MAIN UI WITH TABLE HEADINGS ----------
  @override
  Widget build(BuildContext context) {
    const Color cardDark = Color(0xFF1E293B);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Products", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                _buildMainAddButton(context),
              ],
            ),
            const SizedBox(height: 32),
            // ✅ Table Headings
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text("Name", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                  Expanded(child: Text("Price", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                  Expanded(child: Text("Category", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                  Expanded(child: Text("Actions", textAlign: TextAlign.right, style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            // ✅ Product List
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                    final docs = snapshot.data!.docs;
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(data['name'] ?? "", style: const TextStyle(color: Colors.white))),
                              Expanded(child: Text("₹${data['price']}", style: const TextStyle(color: Colors.white))),
                              Expanded(child: Text(data['category'] ?? "General", style: const TextStyle(color: Colors.blueGrey))),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                                      onPressed: () => _showProductDialog(context, doc: doc),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
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
            ),
          ],
        ),
      ),
    );
  }

  // ---------- DELETE CONFIRMATION ----------
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

  // --- UI Helpers ---
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
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isGreenBorder ? const Color(0xFF10B981) : Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
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

  Widget _buildMainAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProductDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF22D3EE)]), borderRadius: BorderRadius.circular(25)),
        child: const Text("+ Add Product", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}