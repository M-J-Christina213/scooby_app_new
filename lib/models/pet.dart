class Pet {
  final String id;
  final String userId;
  final String name;
  final String type;
  final String breed;
  final int age;
  final String gender;
  final String? color;
  final double? weight;
  final double? height;
  final String? medicalHistory;
  final String? allergies;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;
  final String? startWalkingTime;
  final String? endWalkingTime;

  // Health-related fields
  final DateTime? vaccinationDate;
  final DateTime? medicalCheckupDate;
  final DateTime? prescriptionDate;

  // Meal schedule (HH:mm)
  final String? breakfastTime;
  final String? lunchTime;
  final String? snackTime;
  final String? dinnerTime;

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.gender,
    this.color,
    this.weight,
    this.height,
    this.medicalHistory,
    this.allergies,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.startWalkingTime,
    this.endWalkingTime,
    this.breakfastTime,
    this.lunchTime,
    this.snackTime,
    this.dinnerTime,
    this.vaccinationDate,
    this.medicalCheckupDate,
    this.prescriptionDate,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      color: json['color'],
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      medicalHistory: json['medical_history'],
      allergies: json['food_preference'],
      description: json['description'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      startWalkingTime: json['start_walking_time'],
      endWalkingTime: json['end_walking_time'],
      breakfastTime: json['breakfast_time'],
      lunchTime: json['lunch_time'],
      snackTime: json['snack_time'],
      dinnerTime: json['dinner_time'],
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'type': type,
      'breed': breed,
      'age': age,
      'gender': gender,
      'color': color,
      'weight': weight,
      'height': height,
      'medical_history': medicalHistory,
      'food_preference': allergies,
      'description': description,
      'image_url': imageUrl,
      'start_walking_time': startWalkingTime,
      'end_walking_time': endWalkingTime,
      'breakfast_time': breakfastTime,
      'lunch_time': lunchTime,
      'snack_time': snackTime,
      'dinner_time': dinnerTime,
    };

    if (!forInsert) {
      map['id'] = id;
      map['created_at'] = createdAt?.toIso8601String();
    }

    return map;
  }
}
