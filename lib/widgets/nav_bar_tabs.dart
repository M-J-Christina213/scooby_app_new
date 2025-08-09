import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Home Screen',
        style: TextStyle(fontSize: 24, color: Color(0xFF842EAC), fontWeight: FontWeight.bold),
      ),
    );
  }
}

class MyPetsTab extends StatelessWidget {
  const MyPetsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'My Pets Screen',
        style: TextStyle(fontSize: 24, color: Color(0xFF842EAC), fontWeight: FontWeight.bold),
      ),
    );
  }
}

class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Bookings Screen',
        style: TextStyle(fontSize: 24, color: Color(0xFF842EAC), fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Profile Screen',
        style: TextStyle(fontSize: 24, color: Color(0xFF842EAC), fontWeight: FontWeight.bold),
      ),
    );
  }
}
