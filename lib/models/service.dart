import 'package:flutter/material.dart';

class ServiceItem {
  final IconData icon;
  final String title;
  final String description;
  final String route;
  final Color color;

  const ServiceItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    this.color = const Color(0xFF6A4C93),
  });
}

class NearbyService {
  final String id;
  final String name;
  final String type;
  final double distance;
  final double rating;
  final String imageUrl;
  final bool isOpen;
  final String description;
  final double latitude;
  final double longitude;

  const NearbyService({
    required this.id,
    required this.name,
    required this.type,
    required this.distance,
    required this.rating,
    required this.imageUrl,
    required this.isOpen,
    required this.description,
    required this.latitude,
    required this.longitude,
  });
}