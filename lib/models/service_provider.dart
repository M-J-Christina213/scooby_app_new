class ServiceProvider {
  final int id;
  final String userId;
  final String name;
  final String phoneNo;
  final String email;
  final String city;
  final String role; // Veterinarian, Pet Groomer, Pet Sitter
  final String profileImageUrl;
  final String clinicOrSalonName;
  final String clinicOrSalonAddress;
  final String aboutClinicSalon;
  final String experience;
  final String serviceDescription;
  final String pricingDetails;
  final String consultationFee;
  final List<String> groomingServices;
  final List<String> comfortableWith;
  final String availableTimes;
  final String dislikes;
  final String rate;
  final DateTime createdAt;

  ServiceProvider({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNo,
    required this.email,
    required this.city,
    required this.role,
    required this.profileImageUrl,
    required this.clinicOrSalonName,
    required this.clinicOrSalonAddress,
    required this.aboutClinicSalon,
    required this.experience,
    required this.serviceDescription,
    required this.pricingDetails,
    required this.consultationFee,
    required this.groomingServices,
    required this.comfortableWith,
    required this.availableTimes,
    required this.dislikes,
    required this.rate,
    required this.createdAt,
  });

  factory ServiceProvider.fromMap(Map<String, dynamic> map) {
    return ServiceProvider(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      phoneNo: map['phone_no'],
      email: map['email'],
      city: map['city'],
      role: map['role'],
      profileImageUrl: map['profile_image_url'] ?? '',
      clinicOrSalonName: map['clinic_or_salon_name'] ?? '',
      clinicOrSalonAddress: map['clinic_or_salon_address'] ?? '',
      aboutClinicSalon: map['about_clinic_salon'] ?? '',
      experience: map['experience'] ?? '',
      serviceDescription: map['service_description'] ?? '',
      pricingDetails: map['pricing_details'] ?? '',
      consultationFee: map['consultation_fee'] ?? '',
      groomingServices: List<String>.from(map['grooming_services'] ?? []),
      comfortableWith: List<String>.from(map['comfortable_with'] ?? []),
      availableTimes: map['available_times'] ?? '',
      dislikes: map['dislikes'] ?? '',
      rate: map['rate'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
