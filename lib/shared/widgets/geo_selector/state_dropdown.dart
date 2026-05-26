import 'package:flutter/material.dart';

import '../../services/location_service.dart';
import 'package:mechmate_app/shared/widgets/geo_selector/widgets/glass_dropdown.dart';

class StateDropdown extends StatefulWidget {
  final bool enabled;
  final String countryCode; // ISO2
  final String selectedCode; // state isoCode from dataset
  final ValueChanged<GeoState> onSelected;
  final bool showGoldSelection;

  const StateDropdown({
    super.key,
    required this.enabled,
    required this.countryCode,
    required this.selectedCode,
    required this.onSelected,
    this.showGoldSelection = false,
  });

  @override
  State<StateDropdown> createState() => _StateDropdownState();
}

class _StateDropdownState extends State<StateDropdown> {
  final LocationService _locationService = LocationService();

  bool _loading = false;
  String? _error;
  String _query = '';

  final List<GeoState> _states = [];

  Future<void> _loadStates() async {
    if (!widget.enabled || widget.countryCode.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _query = _query; // keep current search
    });

    try {
      final loaded = await _locationService.getStatesForCountry(
        widget.countryCode,
      );
      setState(() {
        _states
          ..clear()
          ..addAll(loaded);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  @override
  void didUpdateWidget(covariant StateDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryCode != widget.countryCode ||
        oldWidget.enabled != widget.enabled) {
      _states.clear();
      _loadStates();
    }
  }

  List<GeoState> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _states;
    return _states.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  GeoState? get _selected {
    if (widget.selectedCode.isEmpty) return null;
    return _states.where((s) => s.code == widget.selectedCode).toList().firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final goldBorder = widget.showGoldSelection
        ? Border.all(color: Colors.orange.withValues(alpha: 0.95), width: 1.6)
        : null;

    final displayText = _selected?.name ?? '';

    return GlassDropdown<GeoState>(
      enabled: widget.enabled && widget.countryCode.isNotEmpty,
      label: 'State / Province',
      value: _selected,
      displayText: displayText.isEmpty ? 'Choose state' : displayText,
      loading: _loading,
      errorText: _error,
      goldBorder: goldBorder,
      searchText: _query,
      onSearchChanged: (v) => setState(() => _query = v),
      items: _results,
      itemToString: (s) => s.name,
      onChanged: (s) {
        if (s == null) return;
        widget.onSelected(s);
      },
      emptyText: _loading
          ? null
          : _results.isEmpty
              ? 'No states match your search.'
              : null,
      textStyle: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

extension on List<GeoState> {
  GeoState? get firstOrNull => isEmpty ? null : first;
}
