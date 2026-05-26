import 'package:flutter/material.dart';

import 'country_dropdown.dart';
import 'state_dropdown.dart';
import 'city_dropdown.dart';

import 'package:mechmate_app/shared/widgets/geo_selector/models/geo_selection.dart';

class GeoSelector extends StatefulWidget {
  final GeoSelection initial;
  final ValueChanged<GeoSelection> onChanged;
  final bool enabled;

  const GeoSelector({
    super.key,
    this.initial = const GeoSelection.empty(),
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<GeoSelector> createState() => _GeoSelectorState();
}

class _GeoSelectorState extends State<GeoSelector> with TickerProviderStateMixin {
  late GeoSelection _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.initial;
  }

  void _update(GeoSelection next) {
    setState(() => _sel = next);
    widget.onChanged(next);
  }

  bool get _countryReady => _sel.countryCode.isNotEmpty;
  bool get _stateReady => _sel.stateCode.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.primary; // App uses primaryOrange

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GlassDividerLabel(
          label: 'Country',
          gold: gold,
          enabled: widget.enabled,
        ),
        const SizedBox(height: 8),
        CountryDropdown(
          enabled: widget.enabled,
          selectedCode: _sel.countryCode,
          onSelected: (country) {
            _update(
              _sel.copyWith(
                country: country.name,
                countryCode: country.code,
                // reset dependent
                state: '',
                stateCode: '',
                city: '',
                cityCode: '',
              ),
            );
          },
          showGoldSelection: _sel.countryCode.isNotEmpty,
        ),
        const SizedBox(height: 14),

        _GlassDividerLabel(
          label: 'State / Province',
          gold: gold,
          enabled: widget.enabled,
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: widget.enabled && _countryReady ? 1 : 0.6,
          duration: const Duration(milliseconds: 220),
          child: StateDropdown(
            enabled: widget.enabled && _countryReady,
            selectedCode: _sel.stateCode,
            onSelected: (state) {
              _update(
                _sel.copyWith(
                  state: state.name,
                  stateCode: state.code,
                  // reset dependent
                  city: '',
                  cityCode: '',
                ),
              );
            },
            countryCode: _sel.countryCode,
            showGoldSelection: _sel.stateCode.isNotEmpty,
          ),
        ),
        const SizedBox(height: 14),

        _GlassDividerLabel(
          label: 'City',
          gold: gold,
          enabled: widget.enabled,
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: widget.enabled && _stateReady ? 1 : 0.6,
          duration: const Duration(milliseconds: 220),
          child: CityDropdown(
            enabled: widget.enabled && _stateReady,
            countryCode: _sel.countryCode,
            stateCode: _sel.stateCode,
            selectedName: _sel.city,
            onSelected: (city) {
              _update(
                _sel.copyWith(
                  city: city.name,
                  cityCode: city.id ?? '',
                ),
              );
            },
            showGoldSelection: _sel.city.isNotEmpty,
          ),
        ),
      ],
    );
  }
}

class _GlassDividerLabel extends StatelessWidget {
  final String label;
  final Color gold;
  final bool enabled;

  const _GlassDividerLabel({
    required this.label,
    required this.gold,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: enabled ? 1 : 0.7,
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 16,
            color: enabled ? gold : (isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
