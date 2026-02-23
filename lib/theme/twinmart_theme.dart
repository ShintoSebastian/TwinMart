import 'package:flutter/material.dart';

class TwinMartTheme {
  // Brand Colors
  static const Color brandGreen = Color(0xFF1DB98A);
  static const Color brandTeal = Color(0xFF15A196);
  static const Color brandBlue = Color(0xFF2196F3);
  static const Color bgLight = Color(0xFFF4F9F8);
  static const Color darkText = Color(0xFF1A1A1A);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [brandGreen, brandTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mixGradient = LinearGradient(
    colors: [brandBlue, brandGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Common Decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.8),
    borderRadius: BorderRadius.circular(25),
    border: Border.all(color: Colors.white.withOpacity(0.5)),
  );

  // Background Blobs Utility
  static Widget bgBlob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
  // Branded Logo Widget
  static Widget brandLogo({double size = 26, Color? color}) {
    return Container(
      padding: EdgeInsets.all(size * 0.25),
      decoration: BoxDecoration(
        color: color ?? brandGreen,
        borderRadius: BorderRadius.circular(size * 0.6),
        boxShadow: [
          BoxShadow(
            color: (color ?? brandGreen).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Icon(
        Icons.shopping_cart_rounded,
        color: Colors.white,
        size: size,
      ),
    );
  }

  // Branded Text Widget (Twin in Black, Mart in Green)
  static Widget brandText({double fontSize = 28, FontWeight fontWeight = FontWeight.bold}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "Twin",
            style: TextStyle(color: darkText, fontSize: fontSize, fontWeight: fontWeight),
          ),
          TextSpan(
            text: "Mart",
            style: TextStyle(color: brandGreen, fontSize: fontSize, fontWeight: fontWeight),
          ),
        ],
      ),
    );
  }
}
