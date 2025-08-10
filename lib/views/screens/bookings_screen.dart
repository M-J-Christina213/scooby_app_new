import 'package:flutter/material.dart';

class BookingsScreen extends StatelessWidget {
  // Dummy data for bookings and reminders
  final List<Map<String, String>> bookings = [
    {'title': 'Dog Walking', 'date': '2024-07-01', 'time': '10:00 AM'},
    {'title': 'Vet Appointment', 'date': '2024-07-03', 'time': '02:00 PM'},
  ];

  final List<Map<String, String>> reminders = [
    {'reminder': 'Feed Scooby', 'time': '08:00 AM'},
    {'reminder': 'Give medicine', 'time': '09:00 PM'},
  ];

  BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings & Reminders'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Bookings', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 10),
              ...bookings.map((booking) => Card(
                    child: ListTile(
                      leading: Icon(Icons.event),
                      title: Text(booking['title']!),
                      subtitle: Text('${booking['date']} at ${booking['time']}'),
                    ),
                  )),
              SizedBox(height: 30),
              Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 10),
              ...reminders.map((reminder) => Card(
                    child: ListTile(
                      leading: Icon(Icons.alarm),
                      title: Text(reminder['reminder']!),
                      subtitle: Text('Time: ${reminder['time']}'),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}