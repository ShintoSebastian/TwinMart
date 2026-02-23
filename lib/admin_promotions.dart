import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageOffersPage extends StatelessWidget {
  const ManageOffersPage({super.key});

  void _showOfferDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final titleController = TextEditingController(text: doc != null ? doc['title'] : "");
    final subtitleController = TextEditingController(text: doc != null ? doc['subtitle'] : "");
    final btnTextController = TextEditingController(text: doc != null ? doc['btnText'] : "Shop Now");
    final orderController = TextEditingController(text: doc != null ? doc['order'].toString() : "0");
    
    String selectedIcon = doc != null ? doc['icon'] : "shopping_cart";
    String selectedGradient = doc != null ? doc['gradientType'] : "green";
    String selectedAction = doc != null ? doc['action'] : "online_shop";
    String selectedTargetCategory = doc != null && (doc.data() as Map).containsKey('targetCategory') 
        ? doc['targetCategory'] 
        : "All Products";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                doc == null ? "Add New Offer" : "Edit Offer",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Offer Title"),
                    _buildTextField("e.g. Fresh Finds", titleController, isGreen: true),
                    
                    _buildLabel("Subtitle / Description"),
                    _buildTextField("e.g. Up to 30% Off", subtitleController),
                    
                    _buildLabel("Button Text"),
                    _buildTextField("e.g. Claim Now", btnTextController),

                    _buildLabel("Display Order (0, 1, 2...)"),
                    _buildTextField("0", orderController),

                    const SizedBox(height: 16),
                    _buildLabel("Visual Style"),
                    Row(
                      children: [
                        Expanded(child: _buildDropdown(
                          label: "Icon",
                          value: selectedIcon,
                          items: ["shopping_cart", "electronics", "budget", "savings", "stars"],
                          onChanged: (v) => setDialogState(() => selectedIcon = v!),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDropdown(
                          label: "Color",
                          value: selectedGradient,
                          items: ["green", "blue", "orange", "purple"],
                          onChanged: (v) => setDialogState(() => selectedGradient = v!),
                        )),
                      ],
                    ),

                    _buildLabel("Click Action"),
                    _buildDropdown(
                      label: "Action",
                      value: selectedAction,
                      items: ["online_shop", "budget_screen"],
                      onChanged: (v) => setDialogState(() => selectedAction = v!),
                    ),

                    if (selectedAction == "online_shop") ...[
                      _buildLabel("Target Category (Optional)"),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                        builder: (context, snapshot) {
                          List<String> categories = ["All Products"];
                          if (snapshot.hasData) {
                            for (var d in snapshot.data!.docs) {
                              categories.add(d['name'] ?? "");
                            }
                          }
                          
                          // Ensure valid selection
                          if (!categories.contains(selectedTargetCategory)) {
                             selectedTargetCategory = "All Products";
                          }

                          return _buildDropdown(
                            label: "Category",
                            value: selectedTargetCategory,
                            items: categories,
                            onChanged: (v) => setDialogState(() => selectedTargetCategory = v!),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                GestureDetector(
                  onTap: () async {
                    if (titleController.text.isEmpty) return;
                    
                    final data = {
                      'title': titleController.text.trim(),
                      'subtitle': subtitleController.text.trim(),
                      'btnText': btnTextController.text.trim(),
                      'order': int.tryParse(orderController.text) ?? 0,
                      'icon': selectedIcon,
                      'gradientType': selectedGradient,
                      'action': selectedAction,
                      'targetCategory': selectedAction == "online_shop" ? selectedTargetCategory : null,
                      'timestamp': FieldValue.serverTimestamp(),
                    };

                    if (doc == null) {
                      await FirebaseFirestore.instance.collection('promotions').add(data);
                    } else {
                      await FirebaseFirestore.instance.collection('promotions').doc(doc.id).update(data);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: _buildGradientButton(context, doc == null ? "Create" : "Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F172A);
    const Color cardDark = Color(0xFF1E293B);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: isMobile 
            ? AppBar(
                title: const Text("Manage Offers", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Promotional Banners", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => _showOfferDialog(context),
                        child: _buildGradientButton(context, "Add New Offer", hasIcon: true),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 32),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('promotions').orderBy('order').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.campaign_outlined, color: Colors.blueGrey, size: 60),
                              const SizedBox(height: 16),
                              const Text("No active offers yet", style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                              const SizedBox(height: 24),
                              if (isMobile)
                                ElevatedButton(
                                  onPressed: () => _showOfferDialog(context),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                  child: const Text("Create First Offer", style: TextStyle(color: Colors.white)),
                                ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final String docId = docs[index].id;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardDark,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getIconColor(data['gradientType'] ?? "green").withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getIcon(data['icon'] ?? "shopping_cart"), color: _getIconColor(data['gradientType'] ?? "green")),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['title'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text(data['subtitle'] ?? "", style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                      onPressed: () => _showOfferDialog(context, doc: docs[index]),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _showDeleteConfirm(context, docId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (isMobile)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: GestureDetector(
                      onTap: () => _showOfferDialog(context),
                      child: _buildGradientButton(context, "Add New Offer", isMobile: true, hasIcon: true),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Offer", style: TextStyle(color: Colors.white)),
        content: const Text("This banner will be removed from all user dashboards.", style: TextStyle(color: Colors.blueGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('promotions').doc(id).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(String hint, TextEditingController controller, {bool isGreen = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isGreen ? const Color(0xFF10B981) : Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton(BuildContext context, String text, {bool isMobile = false, bool hasIcon = false}) {
    return Container(
      width: isMobile ? double.infinity : null,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF22D3EE)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasIcon) const Icon(Icons.add, color: Colors.white, size: 18),
          if (hasIcon) const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'electronics': return Icons.devices_other;
      case 'budget': return Icons.account_balance_wallet;
      case 'savings': return Icons.savings;
      case 'stars': return Icons.stars;
      default: return Icons.shopping_cart;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      default: return const Color(0xFF10B981);
    }
  }
}
