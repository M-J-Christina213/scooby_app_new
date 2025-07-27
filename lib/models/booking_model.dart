class Booking {
  final String name;
  final String email;
  final String phone;
  final DateTime date;
  final String time;

  Booking({
    required this.name,
    required this.email,
    required this.phone,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'date': date.toIso8601String(),
      'time': time,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
