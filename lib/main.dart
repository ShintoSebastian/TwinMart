import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'signup.dart';
import 'login.dart';
import 'cart_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_wrapper.dart';
import 'package:twinmart_app/firebase_options.dart';
import 'theme/twinmart_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const TwinMartApp(),
    ),
  );
}

class TwinMartApp extends StatelessWidget {
  const TwinMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1DB98A)),
      ),
      // CHANGED: Removed StreamBuilder to stop auto-login
      // Now the app will ALWAYS start at the WelcomeScreen
      home: const WelcomeScreen(), 
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = Color(0xFF1DB98A);
    const Color peachTint = Color(0xFFFFE8D6); 
    const Color mintTint = Color(0xFFCFF2EB);   

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [peachTint, mintTint, Colors.white],
            stops: [0.0, 0.45, 0.9], 
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400), 
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TwinMartTheme.brandLogo(size: 32),
                const SizedBox(height: 12),
                TwinMartTheme.brandText(fontSize: 26),
                const SizedBox(height: 48),

                const Text(
                  'Welcome to TwinMart',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Shop smarter, save time, skip the queue — works online & offline',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF666666), height: 1.5),
                ),
                const SizedBox(height: 60),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: twinGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(), 
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      foregroundColor: const Color(0xFF1A1A1A),
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
}