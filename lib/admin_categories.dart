import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCategoriesPage extends StatelessWidget {
  const ManageCategoriesPage({super.key});

  // --- 1. THE ADD CATEGORY DIALOG ---
  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Add New Category", 
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
                  _buildDialogTextField("Enter category name", nameController, isGreenBorder: true),
                  
                  _buildLabel("Description"),
                  _buildDialogTextField("Enter category description", descController, maxLines: 4),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 24, bottom: 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            _buildDialogCreateButton(context, "Create", nameController, descController),
          ],
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
        bool isMobile = constraints.maxWidth < 750;

        return Scaffold(
          backgroundColor: Colors.transparent, 
          appBar: isMobile 
            ? AppBar(
                title: const Text("Categories", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  const Text("Categories", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 32),
                
                isMobile 
                  ? Column(
                      children: [
                        _buildSearchBar(cardDark, "Search categories..."),
                        const SizedBox(height: 16),
                        _buildMainAddButton(context, isMobile),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildSearchBar(cardDark, "Search categories...")),
                        const SizedBox(width: 24),
                        _buildMainAddButton(context, isMobile),
                      ],
                    ),
                
                const SizedBox(height: 32),
                
                // --- DYNAMIC TABLE START ---
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
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            children: [
                              const Expanded(flex: 2, child: Text("Name", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                              if (!isMobile)
                                const Expanded(flex: 3, child: Text("Description", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                              const Expanded(child: Text("Actions", textAlign: TextAlign.right, style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        
                        // STREAM BUILDER FOR REAL-TIME UPDATES
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('categories')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(child: Text("No categories found", style: TextStyle(color: Colors.blueGrey, fontSize: 16)));
                              }

                              final docs = snapshot.data!.docs;

                              return ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: docs.length,
                                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data() as Map<String, dynamic>;
                                  final docId = docs[index].id;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 2, child: Text(data['name'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                                        if (!isMobile)
                                          Expanded(flex: 3, child: Text(data['description'] ?? "", style: const TextStyle(color: Colors.blueGrey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                                                onPressed: () { /* Add edit logic */ },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                onPressed: () => FirebaseFirestore.instance.collection('categories').doc(docId).delete(),
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

  // --- UI COMPONENTS ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

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
            width: isGreenBorder ? 2 : 1
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
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

  Widget _buildMainAddButton(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () => _showAddCategoryDialog(context),
      child: _buildGradientButton(context, "Add Category", isMobile: isMobile, hasIcon: true),
    );
  }

  Widget _buildDialogCreateButton(BuildContext context, String text, TextEditingController name, TextEditingController desc) {
    return GestureDetector(
      onTap: () async {
        if (name.text.isEmpty) return;
        try {
          await FirebaseFirestore.instance.collection('categories').add({
            'name': name.text,
            'description': desc.text,
            'timestamp': FieldValue.serverTimestamp(),
          });
          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          debugPrint("Error adding category: $e");
        }
      },
      child: _buildGradientButton(context, text),
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