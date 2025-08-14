
class Vaccination {
  final String id; // uuid
  final String petId; // uuid
  final String vaccinationName;
  final String? description;
  final DateTime dateGiven;
  final DateTime? nextDueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Vaccination({
    required this.id,
    required this.petId,
    required this.vaccinationName,
    this.description,
    required this.dateGiven,
    this.nextDueDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Vaccination.fromMap(Map<String, dynamic> m) => Vaccination(
        id: m['id'] as String,
        petId: m['pet_id'] as String,
        vaccinationName: m['vaccination_name'] as String,
        description: m['description'] as String?,
        dateGiven: DateTime.parse(m['date_given'] as String),
        nextDueDate: m['next_due_date'] != null ? DateTime.parse(m['next_due_date'] as String) : null,
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
        updatedAt: m['updated_at'] != null ? DateTime.parse(m['updated_at'] as String) : null,
      );

  Map<String, dynamic> toInsert() => {
        'pet_id': petId,
        'vaccination_name': vaccinationName,
        if (description != null && description!.trim().isNotEmpty) 'description': description,
        'date_given': dateGiven.toIso8601String(),
        if (nextDueDate != null) 'next_due_date': nextDueDate!.toIso8601String(),
      };

  Map<String, dynamic> toUpdate() => {
        'vaccination_name': vaccinationName,
        'description': description,
        'date_given': dateGiven.toIso8601String(),
        'next_due_date': nextDueDate?.toIso8601String(),
      };
}

class MedicalCheckup {
  final String id;
  final String petId;
  final String reason;
  final String? description;
  final DateTime date;

  MedicalCheckup({
    required this.id,
    required this.petId,
    required this.reason,
    this.description,
    required this.date,
  });

  factory MedicalCheckup.fromMap(Map<String, dynamic> m) => MedicalCheckup(
        id: m['id'] as String,
        petId: m['pet_id'] as String,
        reason: m['reason'] as String,
        description: m['description'] as String?,
        date: DateTime.parse(m['date'] as String),
      );

  Map<String, dynamic> toInsert() => {
        'pet_id': petId,
        'reason': reason,
        if (description != null && description!.trim().isNotEmpty) 'description': description,
        'date': date.toIso8601String(),
      };

  Map<String, dynamic> toUpdate() => {
        'reason': reason,
        'description': description,
        'date': date.toIso8601String(),
      };
}

class Prescription {
  final String id;
  final String petId;
  final String medicineName;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;

  Prescription({
    required this.id,
    required this.petId,
    required this.medicineName,
    this.description,
    required this.startDate,
    this.endDate,
  });

  factory Prescription.fromMap(Map<String, dynamic> m) => Prescription(
        id: m['id'] as String,
        petId: m['pet_id'] as String,
        medicineName: m['medicine_name'] as String,
        description: m['description'] as String?,
        startDate: DateTime.parse(m['start_date'] as String),
        endDate: m['end_date'] != null ? DateTime.parse(m['end_date'] as String) : null,
      );

  Map<String, dynamic> toInsert() => {
        'pet_id': petId,
        'medicine_name': medicineName,
        if (description != null && description!.trim().isNotEmpty) 'description': description,
        'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate!.toIso8601String(),
      };

  Map<String, dynamic> toUpdate() => {
        'medicine_name': medicineName,
        'description': description,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };
}
