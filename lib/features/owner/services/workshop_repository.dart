import 'dart:math' show atan2, cos, pi, pow, sin, sqrt;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mechmate_app/features/owner/models/shop_model.dart';
import 'package:mechmate_app/shared/services/services.dart';

class WorkshopRepository {
  final WorkshopApiService _apiService;

  WorkshopRepository(this._apiService);

  Future<List<ShopModel>> fetchNearbyShops({
    required LatLng origin,
    double radiusKm = 10,
    String query = '',
  }) async {
    try {
      final workshops = await _apiService.getNearbyWorkshops(
        lat: origin.latitude,
        lng: origin.longitude,
        radiusKm: radiusKm,
        query: query,
      );

      // Convert WorkshopModel to ShopModel with real rating and calculated distance
      return workshops.map((w) {
        return ShopModel(
          id: w.id,
          name: w.name,
          latitude: w.latitude,
          longitude: w.longitude,
          rating: w.rating,
          distance: _calculateDistance(origin.latitude, origin.longitude, w.latitude, w.longitude),
          isOpen: w.isOpen,
          services: w.services,
        );
      }).toList();
    } catch (e) {
      // Return empty list on failure or rethrow
      return [];
    }
  }

  /// Haversine distance in km between two lat/lng points.
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLng / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (R * c * 10).roundToDouble() / 10; // Round to 1 decimal
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}
