class Pet {
  final String? id;
  final String userId;
  final String name;
  final String? type;
  final String? breed;
  final int? age;
  final String? gender;
  final String? color;
  final double? weight;
  final double? height;
  final String? medicalHistory;
  final String? foodPreference;
  final String? mood;
  final String? healthStatus;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;

  Pet({
    this.id,
    required this.userId,
    required this.name,
    this.type,
    this.breed,
    this.age,
    this.gender,
    this.color,
    this.weight,
    this.height,
    this.medicalHistory,
    this.foodPreference,
    this.mood,
    this.healthStatus,
    this.description,
    this.imageUrl,
    this.createdAt,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: json['type'],
      breed: json['breed'],
      age: json['age'],
      gender: json['gender'],
      color: json['color'],
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      medicalHistory: json['medical_history'],
      foodPreference: json['food_preference'],
      mood: json['mood'],
      healthStatus: json['health_status'],
      description: json['description'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
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
      'food_preference': foodPreference,
      'mood': mood,
      'health_status': healthStatus,
      'description': description,
      'image_url': imageUrl,
    };

    if (!forInsert) {
      map['id'] = id;
      map['created_at'] = createdAt?.toIso8601String();
    }

    return map;
  }
}
