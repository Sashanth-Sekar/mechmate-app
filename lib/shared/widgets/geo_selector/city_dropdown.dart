import 'package:flutter/material.dart';

import '../../services/location_service.dart';
import 'package:mechmate_app/shared/widgets/geo_selector/widgets/glass_dropdown.dart';

class CityDropdown extends StatefulWidget {
  final bool enabled;
  final String countryCode;
  final String stateCode;
  final String selectedName;

  final bool showGoldSelection;
  final ValueChanged<GeoCity> onSelected;

  const CityDropdown({
    super.key,
    required this.enabled,
    required this.countryCode,
    required this.stateCode,
    required this.selectedName,
    required this.onSelected,
    this.showGoldSelection = false,
  });

  @override
  State<CityDropdown> createState() => _CityDropdownState();
}

class _CityDropdownState extends State<CityDropdown> {
  final LocationService _locationService = LocationService();

  bool _loading = false;
  String? _error;
  String _query = '';

  // Keep only the current page subset (pagination-on-demand could be added later).
  List<GeoCity> _cities = [];

  int _page = 0;
  final int _pageSize = 50;

  bool get _canLoad =>
      widget.enabled &&
      widget.countryCode.isNotEmpty &&
      widget.stateCode.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void didUpdateWidget(covariant CityDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final keyChanged =
        oldWidget.countryCode != widget.countryCode ||
        oldWidget.stateCode != widget.stateCode ||
        oldWidget.enabled != widget.enabled;

    if (keyChanged) {
      _page = 0;
      _load(reset: true);
    }
  }

  Future<void> _load({required bool reset}) async {
    if (!_canLoad) {
      setState(() {
        _cities = [];
        _loading = false;
        _error = null;
      });
      return;
    }

    if (reset) {
      _page = 0;
      _cities = [];
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loaded = await _locationService.getCitiesForState(
        countryCode: widget.countryCode,
        stateCode: widget.stateCode,
        searchQuery: _query,
        pageSize: _pageSize,
        page: _page,
      );

      setState(() {
        if (reset) {
          _cities = loaded;
        } else {
          _cities = [..._cities, ...loaded];
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  GeoCity? get _selected {
    if (widget.selectedName.isEmpty) return null;
    return _cities.where((c) => c.name == widget.selectedName).toList().firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final goldBorder = widget.showGoldSelection
        ? Border.all(color: Colors.orange.withValues(alpha: 0.95), width: 1.6)
        : null;

    final displayText = widget.selectedName;

    return GlassDropdown<GeoCity>(
      enabled: widget.enabled && widget.countryCode.isNotEmpty && widget.stateCode.isNotEmpty,
      label: 'City',
      value: _selected,
      displayText: displayText.isEmpty ? 'Choose city' : displayText,
      loading: _loading,
      errorText: _error,
      goldBorder: goldBorder,
      searchText: _query,
      onSearchChanged: (v) {
        setState(() => _query = v);
        _load(reset: true);
      },
      items: _cities,
      itemToString: (c) => c.name,
      onChanged: (c) {
        if (c == null) return;
        widget.onSelected(c);
      },
      emptyText: !_loading
          ? (_query.trim().isEmpty ? 'No cities found.' : 'No cities match your search.')
          : null,
      textStyle: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

extension on List<GeoCity> {
  GeoCity? get firstOrNull => isEmpty ? null : first;
}
