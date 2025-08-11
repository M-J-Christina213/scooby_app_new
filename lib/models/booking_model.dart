class Booking {
  final String id;
  final String petId;
  final String petName; // Added this
  final String serviceProviderEmail;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final DateTime date;
  final String time;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.petId,
    required this.petName, // Added this
    required this.serviceProviderEmail,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.date,
    required this.time,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'pet_id': petId,
        'pet_name': petName, // Added this
        'service_provider_email': serviceProviderEmail,
        'owner_id': ownerId,
        'owner_name': ownerName,
        'owner_phone': ownerPhone,
        'owner_email': ownerEmail,
        'date': date.toIso8601String(),
        'time': time,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory Booking.fromMap(Map<String, dynamic> map) => Booking(
        id: map['id'] ?? '',
        petId: map['pet_id'] ?? '',
        petName: map['pet_name'] ?? '', // Added this
        serviceProviderEmail: map['service_provider_email'] ?? '',
        ownerId: map['owner_id'] ?? '',
        ownerName: map['owner_name'] ?? '',
        ownerPhone: map['owner_phone'] ?? '',
        ownerEmail: map['owner_email'] ?? '',
        date: DateTime.parse(map['date']),
        time: map['time'] ?? '',
        status: map['status'] ?? 'pending',
        createdAt: DateTime.parse(map['created_at']),
      );
}