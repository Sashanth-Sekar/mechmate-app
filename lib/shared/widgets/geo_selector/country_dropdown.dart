import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/location_service.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'package:mechmate_app/shared/widgets/geo_selector/widgets/glass_dropdown.dart';

class CountryDropdown extends StatefulWidget {
  final bool enabled;
  final String selectedCode; // ISO2
  final ValueChanged<GeoCountry> onSelected;
  final bool showGoldSelection;

  const CountryDropdown({
    super.key,
    required this.enabled,
    required this.selectedCode,
    required this.onSelected,
    this.showGoldSelection = false,
  });

  @override
  State<CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  final LocationService _locationService = LocationService();

  bool _loading = false;
  String _query = '';
  String? _error;

  final List<GeoCountry> _countries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CountryDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCode != widget.selectedCode && _countries.isNotEmpty) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loaded = await _locationService.getCountries();
      setState(() {
        _countries
          ..clear()
          ..addAll(loaded);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<GeoCountry> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _countries;
    return _countries.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  GeoCountry? get _selected {
    if (widget.selectedCode.isEmpty) return null;
    return _countries.where((c) => c.code == widget.selectedCode).toList().firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final selectedName = _selected?.name ?? (widget.selectedCode.isEmpty ? '' : widget.selectedCode);

    final goldBorder = widget.showGoldSelection
        ? Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.9), width: 1.6)
        : null;

    return GlassDropdown<GeoCountry>(
      enabled: widget.enabled,
      label: 'Select Country',
      value: _selected,
      displayText: selectedName.isEmpty ? 'Choose country' : selectedName,
      errorText: _error,
      loading: _loading,
      goldBorder: goldBorder,
      searchText: _query,
      onSearchChanged: (v) => setState(() => _query = v),
      items: _results,
      itemToString: (c) => c.name,
      onChanged: (c) {
        if (c == null) return;
        widget.onSelected(c);
      },
      emptyText: _loading ? 'Loading…' : 'No countries match your search.',
    );
  }
}

extension on List<GeoCountry> {
  GeoCountry? get firstOrNull => isEmpty ? null : first;
}
