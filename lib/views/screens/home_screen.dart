import 'package:flutter/material.dart';
import 'package:scooby_app_new/widgets/bottom_nav.dart';
import 'package:scooby_app_new/widgets/nav_bar_tabs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    MyPetsTab(),       // Use the real MyPetsScreen here
    BookingsTab(),
    ProfileTab(),
  ];

  final List<String> _titles = [
    'PetPal',
    'My Pets',
    'Bookings',
    'Profile',
  ];

  void _onNavTap(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: AppBar(
        title: Text(
          _titles[selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF842EAC),
        elevation: 0,
        actions: selectedIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Sign Out',
                  onPressed: () {
                   
                  },
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNav(
        selectedIndex: selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
