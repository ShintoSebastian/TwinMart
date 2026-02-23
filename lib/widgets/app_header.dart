import 'package:flutter/material.dart';
import '../theme/twinmart_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TwinMartTheme.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              TwinMartTheme.brandLogo(size: 24),
              const SizedBox(width: 8),
              TwinMartTheme.brandText(fontSize: 24),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: () {},
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF1ABC9C),
                  child: const Text(
                    'J',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}