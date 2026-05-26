import 'package:mechmate_app/features/owner/owner.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mechmate_app/core/theme/theme.dart';

class MechMapController extends ChangeNotifier {
  MechMapController({
    required LocationService locationService,
    required WorkshopRepository workshopRepository,
  }) : _locationService = locationService,
       _workshopRepository = workshopRepository;

  final LocationService _locationService;
  final WorkshopRepository _workshopRepository;

  GoogleMapController? _googleMapController;
  StreamSubscription<LatLng>? _locationSubscription;
  BitmapDescriptor? _shopIcon;
  BitmapDescriptor? _selectedShopIcon;
  BitmapDescriptor? _clusterIcon;
  double _zoom = 14.5;

  bool isLoading = true;
  bool isFetchingShops = false;
  bool permissionDenied = false;
  String? errorMessage;
  LatLng? userLocation;
  ShopModel? selectedShop;
  List<ShopModel> shops = const [];
  Set<Marker> markers = const {};

  static const fallbackLocation = LatLng(18.5204, 73.8567);

  Future<void> initialize() async {
    isLoading = true;
    permissionDenied = false;
    errorMessage = null;
    notifyListeners();

    try {
      if (!kIsWeb) {
        await _loadMarkerIcons();
      }

      try {
        userLocation = await _locationService.currentLocation();
        _listenToLocationUpdates();
      } on LocationException catch (e) {
        permissionDenied =
            e.failure == LocationFailure.permissionDenied ||
            e.failure == LocationFailure.permissionDeniedForever;
        errorMessage = e.message;
        userLocation = fallbackLocation;
      } catch (_) {
        errorMessage = 'Unable to get your precise location right now.';
        userLocation = fallbackLocation;
      }

      await refreshNearbyShops();
    } catch (_) {
      userLocation ??= fallbackLocation;
      errorMessage ??= 'Unable to load nearby workshops right now.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> attachGoogleMap(GoogleMapController controller) async {
    _googleMapController = controller;
    await animateToUser(zoom: 15);
  }

  void onCameraMove(CameraPosition position) {
    _zoom = position.zoom;
  }

  void onCameraIdle() {
    _rebuildMarkers();
  }

  Future<void> refreshNearbyShops({String query = ''}) async {
    final origin = userLocation ?? fallbackLocation;
    isFetchingShops = true;
    notifyListeners();

    try {
      shops = await _workshopRepository.fetchNearbyShops(
        origin: origin,
        query: query,
      );
      if (selectedShop != null && !shops.any((s) => s.id == selectedShop!.id)) {
        selectedShop = null;
      }
      _rebuildMarkers();
    } catch (_) {
      errorMessage = 'Unable to load nearby workshops right now.';
    } finally {
      isFetchingShops = false;
      notifyListeners();
    }
  }

  Future<void> selectShop(ShopModel shop, {bool showDetails = false}) async {
    selectedShop = shop;
    _rebuildMarkers();
    notifyListeners();
    await animateTo(shop.position, zoom: 16.2);
  }

  Future<void> animateToUser({double zoom = 15.5}) async {
    final location = userLocation ?? fallbackLocation;
    await animateTo(location, zoom: zoom);
  }

  Future<void> animateTo(LatLng target, {double? zoom}) async {
    final controller = _googleMapController;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom ?? max(_zoom, 14),
          tilt: 36,
          bearing: 0,
        ),
      ),
    );
  }

  void _listenToLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.locationStream().listen((
      location,
    ) async {
      userLocation = location;
      await animateTo(location);
      await refreshNearbyShops();
    }, onError: (_) {});
  }

  void _rebuildMarkers() {
    final nextMarkers = <Marker>{};
    final clustered = _clusterShops();

    for (final cluster in clustered) {
      if (cluster.length == 1) {
        final shop = cluster.first;
        final isSelected = selectedShop?.id == shop.id;
        nextMarkers.add(
          Marker(
            markerId: MarkerId(shop.id),
            position: shop.position,
            icon: isSelected
                ? (_selectedShopIcon ?? BitmapDescriptor.defaultMarker)
                : (_shopIcon ?? BitmapDescriptor.defaultMarker),
            zIndexInt: isSelected ? 10 : 1,
            anchor: const Offset(0.5, 0.5),
            onTap: () => selectShop(shop),
          ),
        );
      } else {
        final center = _clusterCenter(cluster);
        nextMarkers.add(
          Marker(
            markerId: MarkerId('cluster-${cluster.map((e) => e.id).join('-')}'),
            position: center,
            icon: _clusterIcon ?? BitmapDescriptor.defaultMarker,
            anchor: const Offset(0.5, 0.5),
            onTap: () => animateTo(center, zoom: min(_zoom + 1.8, 18)),
          ),
        );
      }
    }

    markers = nextMarkers;
  }

  List<List<ShopModel>> _clusterShops() {
    if (_zoom >= 14.6 || shops.length < 8) {
      return shops.map((shop) => [shop]).toList();
    }

    final threshold = _zoom < 12 ? 0.035 : 0.018;
    final clusters = <List<ShopModel>>[];
    for (final shop in shops) {
      final existing = clusters.cast<List<ShopModel>?>().firstWhere(
        (cluster) =>
            cluster != null &&
            _coordinateDistance(cluster.first.position, shop.position) <
                threshold,
        orElse: () => null,
      );
      if (existing == null) {
        clusters.add([shop]);
      } else {
        existing.add(shop);
      }
    }
    return clusters;
  }

  LatLng _clusterCenter(List<ShopModel> cluster) {
    final lat =
        cluster.map((s) => s.latitude).reduce((a, b) => a + b) / cluster.length;
    final lng =
        cluster.map((s) => s.longitude).reduce((a, b) => a + b) /
        cluster.length;
    return LatLng(lat, lng);
  }

  double _coordinateDistance(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return sqrt(dLat * dLat + dLng * dLng);
  }

  Future<void> _loadMarkerIcons() async {
    _shopIcon ??= await _buildMarkerIcon(
      fill: AppColors.primaryOrange,
      stroke: const Color(0xFFFFD166),
      size: 92,
      icon: Icons.build_rounded,
    );
    _selectedShopIcon ??= await _buildMarkerIcon(
      fill: const Color(0xFFFFD166),
      stroke: Colors.white,
      size: 106,
      icon: Icons.build_rounded,
      iconColor: const Color(0xFF12151C),
    );
    _clusterIcon ??= await _buildMarkerIcon(
      fill: const Color(0xFF151922),
      stroke: AppColors.primaryOrange,
      size: 100,
      icon: Icons.garage_rounded,
    );
  }

  Future<BitmapDescriptor> _buildMarkerIcon({
    required Color fill,
    required Color stroke,
    required double size,
    required IconData icon,
    Color iconColor = Colors.white,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center,
      size * 0.42,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(center, size * 0.36, Paint()..color = fill);
    canvas.drawCircle(
      center,
      size * 0.36,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = stroke,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: size * 0.34,
        color: iconColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }
}
