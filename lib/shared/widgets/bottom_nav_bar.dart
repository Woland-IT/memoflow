import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.note_alt_outlined), label: 'Notatki'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Terminarz'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Zakupy'),
      ],
    );
  }
}