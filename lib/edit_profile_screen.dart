import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String currentEmail;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentPhone,
    required this.currentEmail,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final Color twinGreen = const Color(0xFF1DB98A);
  final Color bgLight = const Color(0xFFF4F9F8);

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    phoneController = TextEditingController(text: widget.currentPhone);
    emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ─── Re-auth dialog ───────────────────────────────────────────────────────
  Future<String?> _showReAuthDialog() async {
    final passwordController = TextEditingController();
    bool obscure = true;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: const Text(
              "Confirm your password",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Changing your email requires re-authentication for security. Please enter your current password.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: "Current password",
                    prefixIcon: Icon(Icons.lock_outline, color: twinGreen),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey),
                      onPressed: () => setS(() => obscure = !obscure),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF4F9F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: twinGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, passwordController.text),
                child: const Text("Confirm", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  // ─── Save profile ─────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newEmail = emailController.text.trim();
    final emailChanged = newEmail != widget.currentEmail && newEmail.isNotEmpty;

    setState(() => isSaving = true);

    try {
      // 1️⃣  Email changed → re-authenticate first, then update Auth email
      if (emailChanged) {
        final password = await _showReAuthDialog();
        if (password == null || password.isEmpty) {
          // User cancelled
          setState(() => isSaving = false);
          return;
        }

        // Re-authenticate
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(cred);

        // Update email in Firebase Auth immediately (no verification email)
        await user.updateEmail(newEmail);
      }

      // 2️⃣  Always update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': newEmail,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailChanged
              ? "Profile updated! Use $newEmail to log in next time."
              : "Profile updated successfully!"),
          backgroundColor: twinGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() => isSaving = false);
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = "Incorrect password. Please try again.";
          break;
        case 'requires-recent-login':
          message = "Please re-log in and try again.";
          break;
        case 'email-already-in-use':
          message = "This email is already registered to another account.";
          break;
        case 'invalid-email':
          message = "The email address format is not valid.";
          break;
        default:
          message = e.message ?? "An error occurred. Please try again.";
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      setState(() => isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile. Try again.")),
      );
    }
  }

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
            Text("| Profile", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14)),
          ],
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).iconTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  _inputField("Name", nameController, Icons.person_outline),
                  const SizedBox(height: 20),
                  _inputField("Email Address", emailController, Icons.email_outlined,
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 8),
                  // Email change hint
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.orange[400]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Changing email requires your current password.",
                          style: TextStyle(fontSize: 11, color: Colors.orange[400]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _inputField("Phone Number", phoneController, Icons.phone_android_outlined,
                      keyboard: TextInputType.phone),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: twinGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  elevation: 5,
                ),
                onPressed: isSaving ? null : _saveProfile,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: twinGreen),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : bgLight.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}