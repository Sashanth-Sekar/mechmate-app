import 'dart:async';

import 'package:country_state_city/country_state_city.dart' as csc;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeoLocationException implements Exception {
  final String message;
  const GeoLocationException(this.message);

  @override
  String toString() => message;
}

class GeoCountry {
  final String name;
  final String code; // ISO2 (e.g., IN, US)

  const GeoCountry({
    required this.name,
    required this.code,
  });
}

class GeoState {
  final String name;
  final String code; // ISO2/ISO code (package: isoCode)

  const GeoState({
    required this.name,
    required this.code,
  });
}

class GeoCity {
  final String name;
  final String? id; // not always available in this dataset

  const GeoCity({
    required this.name,
    this.id,
  });
}

class LocationService {
  /// Test override: when set, every `LocationService()` constructor returns
  /// this instance. This allows widget tests to inject a pre-configured
  /// service without modifying any widgets.
  @visibleForTesting
  static LocationService? testOverride;

  /// Reset the test override (restore normal constructor behavior).
  @visibleForTesting
  static void clearTestOverride() {
    testOverride = null;
  }

  static const int _cacheTtlDays = 14;

  static const _prefsKeyCountries = 'geo:countries:v1';
  static const _prefsKeyStatesPrefix = 'geo:states:'; // + countryCode
  static const _prefsKeyCitiesPrefix = 'geo:cities:'; // + countryCode + ':' + stateCode

  static const _timestampKeyPrefix = 'geo:ts:'; // + same suffixes

  final Future<SharedPreferences> _prefsFuture;

  /// Constructor exposed for testing — allows subclasses in test files.
  /// Public callers should use the [LocationService] factory instead.
  @visibleForTesting
  LocationService.test({Future<SharedPreferences>? prefs})
      : _prefsFuture = prefs ?? SharedPreferences.getInstance();

  /// Private constructor used by the factory when no test override is set.
  LocationService._({Future<SharedPreferences>? prefs})
      : _prefsFuture = prefs ?? SharedPreferences.getInstance();

  /// Public factory that returns [testOverride] when set.
  factory LocationService({Future<SharedPreferences>? prefs}) {
    if (testOverride != null) return testOverride!;
    return LocationService._(prefs: prefs);
  }

  bool _isCacheFresh(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    return diff.inDays <= _cacheTtlDays;
  }

  String _timestampKey(String keySuffix) => '$_timestampKeyPrefix$keySuffix';

  Future<DateTime?> _readTimestamp(String keySuffix) async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_timestampKey(keySuffix));
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _writeTimestamp(String keySuffix) async {
    final prefs = await _prefsFuture;
    await prefs.setString(
      _timestampKey(keySuffix),
      DateTime.now().toIso8601String(),
    );
  }

  Future<List<GeoCountry>> getCountries({bool forceRefresh = false}) async {
    final prefs = await _prefsFuture;

    if (!forceRefresh) {
      final ts = await _readTimestamp(_prefsKeyCountries);
      if (ts != null && _isCacheFresh(ts)) {
        final raw = prefs.getStringList(_prefsKeyCountries);
        if (raw != null && raw.isNotEmpty) {
          return raw.map((e) {
            final parts = e.split('|');
            return GeoCountry(name: parts[0], code: parts[1]);
          }).toList();
        }
      }
    }

    try {
      final countries = await csc.getAllCountries();
      final mapped = countries
          .map((co) => GeoCountry(name: co.name, code: co.isoCode))
          .toList();

      final encoded = mapped.map((c) => '${c.name}|${c.code}').toList();
      await prefs.setStringList(_prefsKeyCountries, encoded);
      await _writeTimestamp(_prefsKeyCountries);
      return mapped;
    } catch (e) {
      throw GeoLocationException('Failed to load countries: $e');
    }
  }

  Future<List<GeoState>> getStatesForCountry(
    String countryCode, {
    bool forceRefresh = false,
  }) async {
    final prefs = await _prefsFuture;
    final keySuffix = '$_prefsKeyStatesPrefix$countryCode';

    if (!forceRefresh) {
      final ts = await _readTimestamp(keySuffix);
      if (ts != null && _isCacheFresh(ts)) {
        final raw = prefs.getStringList(keySuffix);
        if (raw != null && raw.isNotEmpty) {
          return raw.map((e) {
            final parts = e.split('|');
            return GeoState(name: parts[0], code: parts[1]);
          }).toList();
        }
      }
    }

    try {
      final states = await csc.getStatesOfCountry(countryCode);
      final mapped = states
          .map((s) => GeoState(name: s.name, code: s.isoCode))
          .toList();

      final encoded = mapped.map((s) => '${s.name}|${s.code}').toList();
      await prefs.setStringList(keySuffix, encoded);
      await _writeTimestamp(keySuffix);
      return mapped;
    } catch (e) {
      throw GeoLocationException('Failed to load states: $e');
    }
  }

  Future<List<GeoCity>> getCitiesForState({
    required String countryCode,
    required String stateCode,
    String? searchQuery,
    int pageSize = 50,
    int page = 0,
    bool forceRefresh = false,
  }) async {
    // NOTE: country_state_city exposes getStateCities which returns all cities
    // for that state. To keep performance acceptable, we:
    // 1) cache the full list for that state
    // 2) apply search filtering and pagination on the client.
    final prefs = await _prefsFuture;
    final keySuffix = '$_prefsKeyCitiesPrefix$countryCode:$stateCode';

    List<GeoCity> allCities = [];

    if (!forceRefresh) {
      final ts = await _readTimestamp(keySuffix);
      if (ts != null && _isCacheFresh(ts)) {
        final raw = prefs.getStringList(keySuffix);
        if (raw != null && raw.isNotEmpty) {
          allCities = raw.map((e) {
            final parts = e.split('|');
            return GeoCity(name: parts[0], id: parts.length > 1 ? parts[1] : null);
          }).toList();
        }
      }
    }

    if (allCities.isEmpty) {
      try {
        final cities = await csc.getStateCities(countryCode, stateCode);
        allCities = cities
            .map((city) => GeoCity(name: city.name, id: null))
            .toList();

        final encoded = allCities.map((c) => '${c.name}|').toList();
        await prefs.setStringList(keySuffix, encoded);
        await _writeTimestamp(keySuffix);
      } catch (e) {
        throw GeoLocationException('Failed to load cities: $e');
      }
    }

    final normalizedQuery = (searchQuery ?? '').trim().toLowerCase();
    final filtered = normalizedQuery.isEmpty
        ? allCities
        : allCities
            .where((c) => c.name.toLowerCase().contains(normalizedQuery))
            .toList();

    final start = page * pageSize;
    final end = start + pageSize;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }
}

/// Convenience mapper for Firestore payload requirement.
Map<String, String> toGeoFirestorePayload({
  required GeoCountry country,
  required GeoState state,
  required GeoCity city,
}) {
  return {
    'country': country.name,
    'countryCode': country.code,
    'state': state.name,
    'stateCode': state.code,
    'city': city.name,
  };
}
