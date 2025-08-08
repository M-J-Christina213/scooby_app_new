class ServiceProvider {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String role;
  final String serviceRole;
  final String experience;
  final String description;

  ServiceProvider({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.role,
    required this.serviceRole,
    required this.experience,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'role': role,
      'service_role': serviceRole,
      'experience': experience,
      'description': description,
    };
  }

  factory ServiceProvider.fromMap(Map<String, dynamic> map) {
    return ServiceProvider(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      city: map['city'],
      role: map['role'],
      serviceRole: map['service_role'],
      experience: map['experience'],
      description: map['description'],
    );
  }

  get clinicOrSalonName => null;
}
