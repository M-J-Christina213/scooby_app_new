// ignore_for_file: unused_element

import 'package:flutter/material.dart';

class PetProfileCard extends StatelessWidget {
  final Map<String, dynamic> petData;
  const PetProfileCard({super.key, required this.petData});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(radius: 36, backgroundImage: petData['image_url'] != null ? NetworkImage(petData['image_url']) : null),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(petData['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Breed: ${petData['breed'] ?? '-'}'),
                  Text('Age: ${petData['age'] ?? '-'}'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}