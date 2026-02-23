import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'login.dart';
import 'main_wrapper.dart';
import 'main.dart'; 
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = TwinMartTheme.brandGreen;

    return Scaffold(
      backgroundColor: TwinMartTheme.bgLight,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -100,
            left: -100,
            size: 300,
            color: TwinMartTheme.brandGreen.withOpacity(0.2),
          ),
          TwinMartTheme.bgBlob(
            bottom: -50,
            right: -80,
            size: 280,
            color: TwinMartTheme.brandBlue.withOpacity(0.15),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              TwinMartTheme.brandLogo(size: 32),
                              const SizedBox(height: 12),
                              TwinMartTheme.brandText(fontSize: 26),
                              const SizedBox(height: 15),
                              const Text('Create your account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                              const Text('Start your smart shopping journey', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        
                        _buildLabel("Full name"),
                        _buildValidatedField(
                          hint: "John Doe",
                          icon: Icons.person_outline,
                          controller: _nameController,
                          validator: (value) => value == null || value.isEmpty ? 'Full name is required' : null,
                        ),

                        _buildLabel("Email address"),
                        _buildValidatedField(
                          hint: "you@gmail.com",
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email is required';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Enter a valid email address';
                            return null;
                          },
                        ),

                        _buildLabel("Phone number"),
                        _buildValidatedField(
                          hint: "+91 98765 43210",
                          icon: Icons.phone_outlined,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Phone number is required';
                            if (value.length < 10) return 'Enter a valid phone number';
                            return null;
                          },
                        ),

                        _buildLabel("Password"),
                        _buildValidatedField(
                          hint: "********",
                          icon: Icons.lock_outline,
                          controller: _passwordController,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password is required';
                            if (value.length < 6) return 'Minimum 6 characters required';
                            
                            bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
                            bool hasLowercase = value.contains(RegExp(r'[a-z]'));
                            bool hasDigits = value.contains(RegExp(r'[0-9]'));
                            bool hasSpecialCharacters = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

                            if (!hasUppercase) return 'Must include an uppercase letter';
                            if (!hasLowercase) return 'Must include a lowercase letter';
                            if (!hasDigits) return 'Must include a number';
                            if (!hasSpecialCharacters) return 'Must include a special symbol';
                            
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 25),

                        Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Color(0xFF179A73), offset: Offset(0, 5))],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: twinGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                : const Text('Create account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                            child: const Text.rich(TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: Colors.grey),
                              children: [TextSpan(text: "Sign in", style: TextStyle(color: twinGreen, fontWeight: FontWeight.bold))],
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.grey, size: 20),
              label: const Text("Back", style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(top: 12, bottom: 6), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)));
  }

  Widget _buildValidatedField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 20),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF0F7FF),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        // Red borders for mandatory field failure
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 2)),
      ),
    );
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      _createAccount();
    }
  }

  void _createAccount() async {
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Successful! Please Login.')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'An unknown error occurred.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}