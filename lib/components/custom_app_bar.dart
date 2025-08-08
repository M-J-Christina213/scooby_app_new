import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String ownerName;
  final VoidCallback onLogout;

  const CustomAppBar({
    super.key,
    required this.ownerName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          // Logo placeholder - replace with your actual logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6A4C93),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Hi, $ownerName',
            style: const TextStyle(
              color: Color(0xFF2D2D2D),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Color(0xFF6A4C93)),
          tooltip: 'Sign Out',
          onPressed: onLogout,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
