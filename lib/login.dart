import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'signup.dart';
import 'main_wrapper.dart';
import 'main.dart';
import 'admin_dashboard.dart';
import 'intro_page.dart';
import 'animated_route.dart';
import 'forgot_password_screen.dart'; // ✅ Ensure this file is created
import 'package:twinmart_app/theme/twinmart_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ New method to handle forgot password navigation
  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = Color(0xFF1DB98A);
    const Color twinGreenShadow = Color(0xFF179A73);
    const Color fieldBg = Color(0xFFF0F7FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            }
          },
          icon: const Icon(Icons.arrow_back, color: Colors.grey, size: 20),
          label: const Text("Back",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(twinGreen),
                const SizedBox(height: 30),
                const Text('Welcome back',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                const Text('Sign in to your account to continue',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
                const SizedBox(height: 35),
                _buildFieldLabel("Email address"),
                _buildInputField("you@gmail.com", Icons.email_outlined, fieldBg,
                    _emailController),
                const SizedBox(height: 12),
                _buildPasswordFieldLabel(twinGreen),
                _buildInputField("********", Icons.lock_outline, fieldBg,
                    _passwordController,
                    isPassword: true),
                const SizedBox(height: 35),
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                          color: twinGreenShadow, offset: Offset(0, 5))
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: twinGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white))
                        : const Text('Sign in',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignupScreen())),
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                            text: "Sign up",
                            style: TextStyle(
                                color: twinGreen,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Color green) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TwinMartTheme.brandLogo(size: 32),
        const SizedBox(width: 12),
        TwinMartTheme.brandText(fontSize: 32),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }

  Widget _buildPasswordFieldLabel(Color green) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Password",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        TextButton(
          onPressed: _navigateToForgotPassword, // ✅ Updated to navigate to reset screen
          child: Text("Forgot password?",
              style: TextStyle(
                  color: green,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildInputField(String hint, IconData icon, Color bg,
      TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }

  void _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Wait a moment!", "Please fill in both your email and password to continue.");
      return;
    }

    setState(() => _isLoading = true);

    if (email == "admin@gmail.com" && password == "admin") {
      setState(() => _isLoading = false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
        (route) => false,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        animatedPageRoute(const IntroPage()),
        (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Something went wrong. Please check your internet connection and try again.";
      
      if (e.code == 'user-not-found') {
        errorMessage = "No account found for this email. Would you like to create one?";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = "The password you entered is incorrect. Please try again or reset your password.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "That email address doesn't look quite right. Please check for typos.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "This account has been disabled. Please contact support.";
      }

      _showErrorDialog("Login Failed", errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 35),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB98A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text("Got it", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}