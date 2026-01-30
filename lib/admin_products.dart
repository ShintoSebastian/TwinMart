import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageProductsPage extends StatelessWidget {
  const ManageProductsPage({super.key});

  // --- 1. THE DIALOG FUNCTION ---
  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final barcodeController = TextEditingController();
    final imageUrlController = TextEditingController();
    
    // Track the selection state inside the modal
    String selectedCategory = "Select category";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // REQUIRED: StatefulBuilder allows the dropdown to visually update
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return LayoutBuilder(
              builder: (context, dialogConstraints) {
                bool isSmallDialog = dialogConstraints.maxWidth < 400;

                return AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Add New Product", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.blueGrey, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: SizedBox(
                      width: 450,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Name"),
                          _buildDialogTextField("Enter product name", nameController, isGreenBorder: true),
                          
                          _buildLabel("Description"),
                          _buildDialogTextField("Enter description", descController, maxLines: 4),
                          
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: isSmallDialog ? double.infinity : 200,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Price"),
                                    _buildDialogTextField("0.00", priceController),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: isSmallDialog ? double.infinity : 210,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Category"),
                                    // FIXED: Pass current value and a callback to update state
                                    _buildCategoryDropdown(
                                      currentValue: selectedCategory,
                                      onChanged: (val) {
                                        setDialogState(() {
                                          selectedCategory = val!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          _buildLabel("Barcode"),
                          _buildDialogTextField("Scan or enter barcode", barcodeController),
                          
                          _buildLabel("Image URL"),
                          _buildDialogTextField("Enter image URL", imageUrlController),
                        ],
                      ),
                    ),
                  ),
                  actionsPadding: const EdgeInsets.only(right: 24, bottom: 24),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                    ),
                    // Pass the final category selection to the create logic
                    _buildDialogCreateButton(context, nameController, descController, priceController, barcodeController, imageUrlController, selectedCategory),
                  ],
                );
              }
            );
          }
        );
      },
    );
  }

  // --- FIXED: THIS IS THE METHOD THE ERROR WAS LOOKING FOR ---
  Widget _buildCategoryDropdown({required String currentValue, required Function(String?) onChanged}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        List<DropdownMenuItem<String>> items = [
          const DropdownMenuItem(value: "Select category", child: Text("Select category", style: TextStyle(color: Colors.blueGrey, fontSize: 13)))
        ];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            String catName = doc['name'] ?? "Unnamed";
            items.add(DropdownMenuItem(value: catName, child: Text(catName, style: const TextStyle(color: Colors.white, fontSize: 13))));
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
      }
    );
  }

  Widget _buildDialogCreateButton(BuildContext context, TextEditingController name, TextEditingController desc, TextEditingController price, TextEditingController barcode, TextEditingController image, String category) {
    return GestureDetector(
      onTap: () async {
        if (name.text.isEmpty || category == "Select category") return;
        try {
          await FirebaseFirestore.instance.collection('products').add({
            'name': name.text,
            'description': desc.text,
            'price': double.tryParse(price.text) ?? 0.0,
            'barcode': barcode.text,
            'imageUrl': image.text,
            'category': category, // Now correctly saves "digital" or any chosen category
            'timestamp': FieldValue.serverTimestamp(),
          });
          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          debugPrint("Error: $e");
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF22D3EE)]),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F172A);
    const Color cardDark = Color(0xFF1E293B);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 750;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Products", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    _buildMainAddButton(context),
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
                        // Table Header
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            children: [
                              const Expanded(flex: 2, child: Text("Name", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                              const Expanded(child: Text("Price", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                              if (!isMobile) const Expanded(child: Text("Category", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                              const Expanded(child: Text("Actions", textAlign: TextAlign.right, style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        
                        // STREAM BUILDER FOR REAL-TIME PRODUCTS
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('products').orderBy('timestamp', descending: true).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                              final docs = snapshot.data!.docs;
                              if (docs.isEmpty) return const Center(child: Text("No products found", style: TextStyle(color: Colors.blueGrey)));
                              
                              return ListView.separated(
                                itemCount: docs.length,
                                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data() as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 2, child: Text(data['name'] ?? "", style: const TextStyle(color: Colors.white))),
                                        Expanded(child: Text("₹${data['price']}", style: const TextStyle(color: Colors.white))),
                                        if (!isMobile) Expanded(child: Text(data['category'] ?? "General", style: const TextStyle(color: Colors.blueGrey))),
                                        const Expanded(child: Icon(Icons.more_vert, color: Colors.blueGrey)),
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

  // --- UI ATOMS ---
  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)));

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

  Widget _buildMainAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddProductDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF22D3EE)]), borderRadius: BorderRadius.circular(25)),
        child: const Text("+ Add Product", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}