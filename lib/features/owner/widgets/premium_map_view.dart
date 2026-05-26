import 'package:mechmate_app/features/owner/owner.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mechmate_app/core/theme/theme.dart';

class PremiumMapView extends StatelessWidget {
  final MechMapController controller;
  final EdgeInsets padding;

  const PremiumMapView({
    super.key,
    required this.controller,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _BrowserWorkshopMap(controller: controller);
    }

    final target =
        controller.userLocation ?? MechMapController.fallbackLocation;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: target,
        zoom: 14.5,
        tilt: 28,
      ),
      markers: controller.markers,
      myLocationEnabled: !controller.permissionDenied,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: true,
      padding: padding,
      style: MechMapStyles.automobileDark,
      onMapCreated: controller.attachGoogleMap,
      onCameraMove: controller.onCameraMove,
      onCameraIdle: controller.onCameraIdle,
    );
  }
}

class _BrowserWorkshopMap extends StatelessWidget {
  final MechMapController controller;

  const _BrowserWorkshopMap({required this.controller});

  @override
  Widget build(BuildContext context) {
    final origin =
        controller.userLocation ?? MechMapController.fallbackLocation;
    final selected = controller.selectedShop;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10141B), Color(0xFF18202B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CustomPaint(painter: _RoadMapPainter())),
              Positioned(
                left: size.width / 2 - 10,
                top: size.height / 2 - 10,
                child: const _UserLocationPin(),
              ),
              for (final shop in controller.shops)
                _ShopMarker(
                  shop: shop,
                  offset: _project(shop, origin, size),
                  selected: selected?.id == shop.id,
                  onTap: () => controller.selectShop(shop),
                ),
              if (selected != null)
                _SelectedShopBubble(
                  shop: selected,
                  offset: _project(selected, origin, size),
                  mapSize: size,
                ),
            ],
          ),
        );
      },
    );
  }

  Offset _project(ShopModel shop, LatLng origin, Size size) {
    const span = 0.06;
    final x = (0.5 + (shop.longitude - origin.longitude) / span)
        .clamp(0.08, 0.92)
        .toDouble();
    final y = (0.5 - (shop.latitude - origin.latitude) / span)
        .clamp(0.12, 0.88)
        .toDouble();
    return Offset(size.width * x, size.height * y);
  }
}

class _RoadMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final majorRoad = Paint()
      ..color = const Color(0xFF303947)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final minorRoad = Paint()
      ..color = const Color(0xFF252C37)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final accentRoad = Paint()
      ..color = AppColors.primaryOrange.withValues(alpha: 0.44)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final water = Paint()..color = const Color(0xFF0A2634);

    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.88),
      size.shortestSide * 0.28,
      water,
    );

    final diagonal = Path()
      ..moveTo(-20, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.44,
        size.width + 20,
        size.height * 0.22,
      );
    canvas.drawPath(diagonal, majorRoad);
    canvas.drawPath(diagonal, accentRoad);

    final cross = Path()
      ..moveTo(size.width * 0.18, -20)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.3,
        size.width * 0.64,
        size.height * 0.42,
        size.width * 0.72,
        size.height + 20,
      );
    canvas.drawPath(cross, minorRoad);

    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.18 + i * 0.18);
      canvas.drawLine(
        Offset(-20, y),
        Offset(size.width + 20, y + size.height * 0.08),
        minorRoad..strokeWidth = i.isEven ? 4 : 3,
      );
    }

    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.16 + i * 0.22);
      canvas.drawLine(
        Offset(x, -20),
        Offset(x + size.width * 0.08, size.height + 20),
        minorRoad..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShopMarker extends StatelessWidget {
  final ShopModel shop;
  final Offset offset;
  final bool selected;
  final VoidCallback onTap;

  const _ShopMarker({
    required this.shop,
    required this.offset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = selected ? 48.0 : 42.0;
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size / 2,
      width: size,
      height: size,
      child: Tooltip(
        message: shop.name,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? const Color(0xFFFFD166)
                    : AppColors.primaryOrange,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.36),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Icon(
                Icons.build_rounded,
                size: selected ? 23 : 20,
                color: selected ? const Color(0xFF12151C) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserLocationPin extends StatelessWidget {
  const _UserLocationPin();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3B82F6),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.36),
            blurRadius: 18,
            spreadRadius: 8,
          ),
        ],
      ),
      child: const SizedBox(width: 20, height: 20),
    );
  }
}

class _SelectedShopBubble extends StatelessWidget {
  final ShopModel shop;
  final Offset offset;
  final Size mapSize;

  const _SelectedShopBubble({
    required this.shop,
    required this.offset,
    required this.mapSize,
  });

  @override
  Widget build(BuildContext context) {
    final maxLeft = math.max(12.0, mapSize.width - 228);
    final maxTop = math.max(12.0, mapSize.height - 96);
    final left = (offset.dx - 108).clamp(12.0, maxLeft).toDouble();
    final top = (offset.dy - 90).clamp(12.0, maxTop).toDouble();

    return Positioned(
      left: left,
      top: top,
      width: 216,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xEE151922),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x22FFFFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDarkPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${shop.distanceLabel} - ${shop.rating.toStringAsFixed(1)} rating',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
