import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pet Owner Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Alex Johnson',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                'Pet Lover & Owner',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            Divider(height: 32),
            Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('alex.johnson@email.com'),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('+1 234 567 8901'),
            ),
            Divider(height: 32),
            Text(
              'Pet Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: Icon(Icons.pets),
              title: Text('Scooby'),
              subtitle: Text('Golden Retriever, 3 years old'),
            ),
            ListTile(
              leading: Icon(Icons.vaccines),
              title: Text('Vaccinations'),
              subtitle: Text('Up to date'),
            ),
            ListTile(
              leading: Icon(Icons.medical_services),
              title: Text('Vet'),
              subtitle: Text('Dr. Smith, Happy Paws Clinic'),
            ),
          ],
        ),
      ),
    );
  }
}