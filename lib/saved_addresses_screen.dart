import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  // ✅ Function to show the Bottom Sheet for adding an address
  void _showAddAddressDialog(BuildContext context, String userId, Color green) {
    final addressController = TextEditingController();
    String addressType = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to push up with the keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add New Address",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    hintText: "Flat/House No, Building, Street, Area",
                    hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                const Text("Address Type", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _typeChip("Home", addressType == 'Home', green, () {
                      setModalState(() => addressType = 'Home');
                    }),
                    const SizedBox(width: 10),
                    _typeChip("Work", addressType == 'Work', green, () {
                      setModalState(() => addressType = 'Work');
                    }),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () async {
                      if (addressController.text.trim().isNotEmpty) {
                        // ✅ Saves to Firestore
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('userAddresses')
                            .add({
                          'fullAddress': addressController.text.trim(),
                          'type': addressType,
                          'isDefault': false,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      "Save Address",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _typeChip(String label, bool isSelected, Color green, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = Color(0xFF1DB98A);
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        title: const Text("Saved Addresses",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: userId.isEmpty
          ? const Center(child: Text("Please login to view addresses"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('userAddresses')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: twinGreen));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildNoAddressState(twinGreen);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var address = snapshot.data!.docs[index];
                    return _buildAddressCard(context, address, twinGreen, userId);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        // ✅ Triggers the Bottom Sheet
        onPressed: () => _showAddAddressDialog(context, userId, twinGreen),
        backgroundColor: twinGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Address", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildNoAddressState(Color green) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No addresses saved yet", style: TextStyle(color: Colors.blueGrey, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, DocumentSnapshot doc, Color green, String userId) {
    final data = doc.data() as Map<String, dynamic>;
    bool isDefault = data['isDefault'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDefault ? Border.all(color: green, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: green.withOpacity(0.1),
            child: Icon(data['type'] == 'Home' ? Icons.home : Icons.work, color: green),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['type'] ?? "Other", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isDefault)
                      Text("DEFAULT", style: TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(data['fullAddress'] ?? "Address details...", style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text("Edit")),
              const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
            ],
            onSelected: (val) async {
              if (val == 'delete') {
                // ✅ Delete from Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('userAddresses')
                    .doc(doc.id)
                    .delete();
              }
            },
          ),
        ],
      ),
    );
  }
}