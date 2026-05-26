import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShopModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final double distance;
  final bool isOpen;
  final List<String> services;

  const ShopModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.distance,
    this.isOpen = true,
    this.services = const [],
  });

  LatLng get position => LatLng(latitude, longitude);

  String get distanceLabel {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  ShopModel copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? rating,
    double? distance,
    bool? isOpen,
    List<String>? services,
  }) {
    return ShopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      isOpen: isOpen ?? this.isOpen,
      services: services ?? this.services,
    );
  }
}
