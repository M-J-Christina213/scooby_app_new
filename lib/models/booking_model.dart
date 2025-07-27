class Booking {
  final String name;
  final String email;
  final String phone;
  final DateTime date;
  final String time;
  final String serviceProviderEmail; // changed field name

  Booking({
    required this.name,
    required this.email,
    required this.phone,
    required this.date,
    required this.time,
    required this.serviceProviderEmail, // changed here too
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'date': date.toIso8601String(),
      'time': time,
      'serviceProviderEmail': serviceProviderEmail,  // changed key
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
