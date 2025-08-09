import 'package:flutter/material.dart';
import 'package:scooby_app_new/views/screens/my_pets_screen.dart';
import 'package:scooby_app_new/widgets/bottom_nav.dart';
import 'package:scooby_app_new/widgets/nav_bar_tabs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required String userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

   late final List<Widget> _tabs;
  late final String currentUserId;

  @override
  void initState() {
    super.initState();

    currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    _tabs = [
      const HomeTab(),
      MyPetsScreen(userId: currentUserId),
      const BookingsTab(),
      const ProfileTab(),
    ];
  }
  final List<String> _titles = [
    'Home',
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
