// Fake LocationService for widget tests.
//
// Returns hardcoded geo data (India → Maharashtra → Mumbai) without any
// SharedPreferences or network dependency.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mechmate_app/shared/services/location_service.dart';

// ===================================================================
// Fake LocationService
// ===================================================================

/// Returns hardcoded geo data (India → Maharashtra → Mumbai) without any
/// SharedPreferences or network dependency.  Subclasses the test-only
/// constructor [LocationService.test] so its async initialisation is
/// trivially resolved.
class FakeLocationService extends LocationService {
  FakeLocationService() : super.test();

  @override
  Future<List<GeoCountry>> getCountries({bool forceRefresh = false}) async {
    return [const GeoCountry(name: 'India', code: 'IN')];
  }

  @override
  Future<List<GeoState>> getStatesForCountry(
    String countryCode, {
    bool forceRefresh = false,
  }) async {
    return [const GeoState(name: 'Maharashtra', code: 'MH')];
  }

  @override
  Future<List<GeoCity>> getCitiesForState({
    required String countryCode,
    required String stateCode,
    String? searchQuery,
    int pageSize = 50,
    int page = 0,
    bool forceRefresh = false,
  }) async {
    return [const GeoCity(name: 'Mumbai')];
  }
}

/// Pre-warm SharedPreferences and inject a [FakeLocationService] so tests
/// that use geo-selector widgets don't need real SharedPreferences or
/// network access.
///
/// Call this before [pumpWidget] in any widget test that renders a
/// [GeoSelector] or its dropdown components.
Future<void> prewarmAndInjectGeoService(WidgetTester tester) async {
  await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
  });
  LocationService.testOverride = FakeLocationService();
}
