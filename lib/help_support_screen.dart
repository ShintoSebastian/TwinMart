import 'package:flutter/material.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  final Color twinGreen = const Color(0xFF1DB98A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TwinMartTheme.brandLogo(size: 18, context: context),
            const SizedBox(width: 8),
            TwinMartTheme.brandText(fontSize: 18, context: context),
            const SizedBox(width: 10),
            Text(
              "| Help",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color:
              Theme.of(context).iconTheme.color ??
              (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactCard(context),
            const SizedBox(height: 30),
            _buildPastFeedback(context),
            const SizedBox(height: 30),
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildFaqList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: twinGreen,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: twinGreen.withOpacity(0.3), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "How can we help you?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Send our team a direct message for support.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showSupportMsgDialog(context),
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFF1DB98A),
            ),
            label: const Text("Message Support"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: twinGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportMsgDialog(BuildContext context) {
    final msgController = TextEditingController();
    bool isSending = false;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 25,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Send Feedback / Support Request",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: msgController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Describe your issue or suggestion here...",
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: twinGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: isSending
                        ? null
                        : () async {
                            if (msgController.text.trim().isEmpty) return;
                            setState(() => isSending = true);

                            try {
                              String userName = "Unknown User";
                              String userEmail =
                                  FirebaseAuth.instance.currentUser?.email ??
                                  "Unknown Email";

                              // Try to get user data if logged in
                              if (userId != null) {
                                final doc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .get();
                                if (doc.exists) {
                                  userName = doc.data()?['name'] ?? "User";
                                }
                              }

                              await FirebaseFirestore.instance
                                  .collection('support_messages')
                                  .add({
                                    'userId': userId ?? "guest",
                                    'userName': userName,
                                    'userEmail': userEmail,
                                    'message': msgController.text.trim(),
                                    'timestamp': FieldValue.serverTimestamp(),
                                    'status': 'Open',
                                  });

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      "Message sent successfully!",
                                    ),
                                    backgroundColor: twinGreen,
                                  ),
                                );
                              }
                            } catch (e) {
                         setState(() => isSending = false);
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text("Failed to send message: ${e.toString()}"),
                               backgroundColor: Colors.red,
                               duration: const Duration(seconds: 4),
                             ),
                           );
                         }
                      }
                          },
                    child: isSending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Send Message",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPastFeedback(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_messages')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Firestore Error on Support Messages: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTs = aData['timestamp'] as Timestamp?;
          final bTs = bData['timestamp'] as Timestamp?;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return -1;
          if (bTs == null) return 1;
          return bTs.compareTo(aTs);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Recent Interactions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final String status = data['status'] ?? 'Open';
                final String msg = data['message'] ?? '';
                final String? adminReply = data['adminReply'];
                final Timestamp? ts = data['timestamp'] as Timestamp?;
                final String timeStr = ts != null ? ts.toDate().toLocal().toString().split('.')[0] : "Just now";

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(timeStr, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'Open' ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: status == 'Open' ? Colors.orange : Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(msg, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14)),
                      if (adminReply != null && adminReply.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: twinGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: twinGreen.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("TwinMart Support Replied:", style: TextStyle(color: twinGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(adminReply, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14)),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              },
            )
          ],
        );
      },
    );
  }

  Widget _buildFaqList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _faqTile(
            "How do I track my order?",
            "You can track your order in the 'Order History' section of your profile.",
          ),
          const Divider(height: 1),
          _faqTile(
            "What is the return policy?",
            "Items can be returned within 7 days of delivery if they are in original condition.",
          ),
          const Divider(height: 1),
          _faqTile(
            "How do I change my address?",
            "Go to 'Saved Addresses' in your profile settings to add or edit delivery locations.",
          ),
        ],
      ),
    );
  }

  Widget _faqTile(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Text(
            answer,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
