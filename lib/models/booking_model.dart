class Booking {
  final String petId;
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
    required this.petId,
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
        'pet_id': petId,
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
}
