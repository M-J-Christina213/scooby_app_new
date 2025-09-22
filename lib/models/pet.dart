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
  final String? allergies; // Keep as allergies in the model for UI consistency
  
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;

  // NEW: walking time (Postgres "time" columns; send as 'HH:mm:ss')
  final String? startWalkingTime;
  final String? endWalkingTime;

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
      // FIX: Map database field 'food_preference' to model field 'allergies'
      allergies: json['food_preference'],
      description: json['description'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      startWalkingTime: json['start_walking_time'],
      endWalkingTime: json['end_walking_time'],
    );
  }

  get dob => null;

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
      // FIX: Map model field 'allergies' to database field 'food_preference'
      'food_preference': allergies,
      'description': description,
      'image_url': imageUrl,
      'start_walking_time': startWalkingTime,
      'end_walking_time': endWalkingTime,
    };

    if (!forInsert) {
      map['id'] = id;
      map['created_at'] = createdAt?.toIso8601String();
    }

    return map;
  }
}