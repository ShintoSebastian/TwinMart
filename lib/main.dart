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
import 'theme/theme_provider.dart';

import 'admin_dashboard.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const TwinMartApp(),
    ),
  );
}

class TwinMartApp extends StatelessWidget {
  const TwinMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TwinMartTheme.lightTheme,
      darkTheme: TwinMartTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // CHANGED: Removed StreamBuilder to stop auto-login
      // Now the app will ALWAYS start at the WelcomeScreen
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            // Admin Check
            if (snapshot.data?.email == 'admin@gmail.com') {
              return const AdminDashboard();
            }
            return const MainWrapper();
          }
          return const WelcomeScreen();
        },
      ),
    );
  }
}



class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = Color(0xFF1DB98A);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color peachTint = isDark ? const Color(0xFF2C1B10) : const Color(0xFFFFE8D6); 
    final Color mintTint = isDark ? const Color(0xFF102C27) : const Color(0xFFCFF2EB);   
    final Color bgColor = isDark ? TwinMartTheme.bgDark : Colors.white;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [peachTint, mintTint, bgColor],
            stops: const [0.0, 0.45, 0.9], 
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400), 
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TwinMartTheme.brandLogo(size: 32, context: context),
                const SizedBox(height: 12),
                TwinMartTheme.brandText(fontSize: 26, context: context),
                const SizedBox(height: 48),

                const Text(
                  'Welcome to TwinMart',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  'Shop smarter, save time, skip the queue — works online & offline',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : const Color(0xFF666666), height: 1.5),
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