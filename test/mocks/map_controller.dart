// Fake MechMapController for widget tests.
//
// Replaces real platform dependencies (Google Maps, Geolocator) with
// configurable state so tests can exercise loading, empty, error, and
// populated states without any platform-channel crashes or pending timers.

import 'package:mechmate_app/features/owner/owner.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mechmate_app/shared/services/services.dart';

// ===================================================================
// Fake MechMapController
// ===================================================================

/// A fake [MechMapController] that overrides all platform-dependent methods
/// so widget tests can control loading, empty, error, and populated states
/// without Google Maps, Geolocator, or network dependencies.
///
/// Unlike the real controller, [initialize] does NOT auto-resolve the
/// loading state.  Call [resolveLoading] when the test is ready to
/// transition from the loading overlay to the loaded UI.
class FakeMechMapController extends MechMapController {
  FakeMechMapController()
      : super(
          locationService: _FakeOwnerLocationService(),
          workshopRepository: _FakeOwnerWorkshopRepository(),
        );

  // ---- Seam state for test assertions --------------------------------

  /// Whether [initialize] has been called.
  bool initializeCalled = false;

  /// The last query passed to [refreshNearbyShops].
  String? lastQuery;

  bool _loadingResolved = false;

  // ---- Override setters so tests can assign directly -----------------

  @override
  set isLoading(bool v) => super.isLoading = v;
  @override
  set isFetchingShops(bool v) => super.isFetchingShops = v;
  @override
  set permissionDenied(bool v) => super.permissionDenied = v;
  @override
  set errorMessage(String? v) => super.errorMessage = v;
  @override
  set shops(List<ShopModel> v) => super.shops = v;
  @override
  set selectedShop(ShopModel? v) => super.selectedShop = v;

  // ---- Overridden methods ------------------------------------------

  @override
  Future<void> initialize() async {
    initializeCalled = true;
    isLoading = true;
    isFetchingShops = false;
    permissionDenied = false;
    errorMessage = null;
    notifyListeners();

    // Does NOT auto-resolve — the test must call resolveLoading() when
    // ready.  This avoids pending timers that would fail the test.
  }

  /// Transition from loading → completed (idle) state.
  void resolveLoading() {
    if (_loadingResolved) return;
    _loadingResolved = true;
    isLoading = false;
    notifyListeners();
  }

  @override
  Future<void> refreshNearbyShops({String query = ''}) async {
    lastQuery = query;
    isFetchingShops = false;
    notifyListeners();
  }

  @override
  Future<void> animateToUser({double zoom = 15.5}) async {
    // No-op in tests.
  }

  @override
  Future<void> selectShop(ShopModel shop, {bool showDetails = false}) async {
    selectedShop = shop;
    notifyListeners();
  }

  @override
  Future<void> attachGoogleMap(GoogleMapController controller) async {
    // No-op in tests.
  }

  @override
  void onCameraMove(CameraPosition position) {
    // No-op in tests.
  }

  @override
  void onCameraIdle() {
    // No-op in tests.
  }
}

// ===================================================================
// Internal fakes for the controller's constructor dependencies
// ===================================================================

class _FakeOwnerLocationService extends LocationService {
  @override
  Future<LatLng> currentLocation() async {
    return const LatLng(18.5204, 73.8567); // Pune fallback
  }

  @override
  Stream<LatLng> locationStream() {
    return const Stream.empty();
  }
}

class _FakeOwnerWorkshopRepository extends WorkshopRepository {
  _FakeOwnerWorkshopRepository() : super(_FakeOwnerWorkshopApiService());

  @override
  Future<List<ShopModel>> fetchNearbyShops({
    required LatLng origin,
    double radiusKm = 10,
    String query = '',
  }) async {
    return [];
  }
}

class _FakeOwnerWorkshopApiService extends WorkshopApiService {
  _FakeOwnerWorkshopApiService() : super(client: null);
}
