import 'package:mechmate_app/features/owner/owner.dart';
import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'package:mechmate_app/shared/services/services.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  late final MechMapController _mapController;
  ShopModel? _lastPresentedShop;

  @override
  void initState() {
    super.initState();
    _mapController = MechMapController(
      locationService: LocationService(),
      workshopRepository: WorkshopRepository(WorkshopApiService()),
    )..addListener(_onMapChanged);
    _mapController.initialize();
  }

  @override
  void dispose() {
    _mapController
      ..removeListener(_onMapChanged)
      ..dispose();
    super.dispose();
  }

  void _onMapChanged() {
    final selected = _mapController.selectedShop;
    if (selected == null || selected.id == _lastPresentedShop?.id) return;

    _lastPresentedShop = selected;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showWorkshopDetailsSheet(context, selected).whenComplete(() {
        if (_lastPresentedShop?.id == selected.id) {
          _lastPresentedShop = null;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F5F0),
      body: AnimatedBuilder(
        animation: _mapController,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: PremiumMapView(
                  controller: _mapController,
                  padding: const EdgeInsets.only(bottom: 275, top: 96),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: MapGlassSearchBar(
                    readOnly: true,
                    hintText: 'Search nearby workshops',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SearchWorkshopsScreen(),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                bottom: 292,
                child: CurrentLocationButton(
                  onPressed: () => _mapController.animateToUser(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ServiceSelectionCard(
                  shops: _mapController.shops,
                  onBookService: () {
                    final shop =
                        _mapController.selectedShop ??
                        (_mapController.shops.isNotEmpty
                            ? _mapController.shops.first
                            : null);
                    if (shop != null) {
                      showWorkshopDetailsSheet(context, shop);
                    }
                  },
                  onSeeAll: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SearchWorkshopsScreen(),
                    ),
                  ),
                ),
              ),
              LocationStatusOverlay(
                isLoading: _mapController.isLoading,
                permissionDenied: _mapController.permissionDenied,
                message: _mapController.errorMessage,
                onRetry: _mapController.initialize,
              ),
            ],
          );
        },
      ),
    );
  }
}
