import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: const Color(0xFF6A0DAD),
      unselectedItemColor: Colors.grey,
      currentIndex: selectedIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Services'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Adoption'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Community'),
      ],
    );
  }
}
