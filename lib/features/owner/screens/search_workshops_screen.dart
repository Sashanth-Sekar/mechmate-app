import 'package:mechmate_app/features/owner/owner.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'package:mechmate_app/shared/services/services.dart';

class SearchWorkshopsScreen extends StatefulWidget {
  /// Optional — inject a pre-configured controller for testing or advanced
  /// use cases. When omitted the screen creates its own [MechMapController]
  /// with default dependencies.
  final MechMapController? controller;

  /// Optional builder that replaces the default [PremiumMapView].
  ///
  /// Used primarily in widget tests to avoid platform-channel dependencies
  /// (Google Maps requires native platform channels that are unavailable in
  /// `flutter test`).  When provided, this builder is called instead of
  /// rendering a [PremiumMapView].
  final Widget Function(MechMapController)? mapViewBuilder;

  const SearchWorkshopsScreen({
    super.key,
    this.controller,
    this.mapViewBuilder,
  });

  @override
  State<SearchWorkshopsScreen> createState() => _SearchWorkshopsScreenState();
}

class _SearchWorkshopsScreenState extends State<SearchWorkshopsScreen> {
  late final MechMapController _mapController;
  final _searchController = TextEditingController();
  final _listController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mapController = widget.controller ??
        MechMapController(
          locationService: LocationService(),
          workshopRepository: WorkshopRepository(WorkshopApiService()),
        );
    _mapController.addListener(_syncSelectedListItem);
    _mapController.initialize();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _listController.dispose();
    _mapController
      ..removeListener(_syncSelectedListItem)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _mapController.refreshNearbyShops(query: value);
    });
    setState(() {});
  }

  void _syncSelectedListItem() {
    final selected = _mapController.selectedShop;
    if (selected == null || !_listController.hasClients) return;

    final index = _mapController.shops.indexWhere((s) => s.id == selected.id);
    if (index < 0) return;

    _listController.animateTo(
      index * 108,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F5F0),
      body: AnimatedBuilder(
        animation: _mapController,
        builder: (context, _) {
          return SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.textDarkPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: MapGlassSearchBar(
                              controller: _searchController,
                              autofocus: true,
                              hintText: 'Search service or workshop',
                              onChanged: _onSearchChanged,
                              onClear: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.38,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(24),
                              ),
                              child: widget.mapViewBuilder?.call(_mapController) ??
                              PremiumMapView(
                                controller: _mapController,
                                padding: const EdgeInsets.only(bottom: 24),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: 18,
                            child: CurrentLocationButton(
                              onPressed: () => _mapController.animateToUser(),
                            ),
                          ),
                          if (_mapController.isFetchingShops)
                            const Positioned(
                              left: 18,
                              bottom: 24,
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child:
                          _mapController.shops.isEmpty &&
                              !_mapController.isLoading
                          ? const Center(
                              child: Text(
                                'No workshops found nearby',
                                style: TextStyle(
                                  color: AppColors.textDarkSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: _listController,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                18,
                                16,
                                22,
                              ),
                              itemCount: _mapController.shops.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final shop = _mapController.shops[index];
                                final selected =
                                    _mapController.selectedShop?.id == shop.id;
                                return WorkshopListItem(
                                  shop: shop,
                                  selected: selected,
                                  onTap: () async {
                                    await _mapController.selectShop(shop);
                                    if (!context.mounted) return;
                                    showWorkshopDetailsSheet(context, shop);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
                LocationStatusOverlay(
                  isLoading: _mapController.isLoading,
                  permissionDenied: _mapController.permissionDenied,
                  message: _mapController.errorMessage,
                  onRetry: _mapController.initialize,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
