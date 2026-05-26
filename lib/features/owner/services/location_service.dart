import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationException implements Exception {
  final LocationFailure failure;
  final String message;

  const LocationException(this.failure, this.message);

  @override
  String toString() => message;
}

class LocationService {
  static const Duration _locationTimeout = Duration(seconds: 10);

  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 18,
  );

  Future<LatLng> currentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException(
        LocationFailure.serviceDisabled,
        'Location services are switched off.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        LocationFailure.permissionDenied,
        'Location permission was denied.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationFailure.permissionDeniedForever,
        'Location permission is permanently denied.',
      );
    }

    final position =
        await Geolocator.getCurrentPosition(
          locationSettings: _settings,
        ).timeout(
          _locationTimeout,
          onTimeout: () {
            throw const LocationException(
              LocationFailure.unavailable,
              'Location request timed out.',
            );
          },
        );
    return LatLng(position.latitude, position.longitude);
  }

  Stream<LatLng> locationStream() {
    return Geolocator.getPositionStream(
      locationSettings: _settings,
    ).map((position) => LatLng(position.latitude, position.longitude));
  }
}
