import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/features/mechanic/models/workshop_model.dart';
import 'package:mechmate_app/shared/shared.dart';

class WorkshopProfileScreen extends StatefulWidget {
  const WorkshopProfileScreen({super.key});

  @override
  State<WorkshopProfileScreen> createState() => _WorkshopProfileScreenState();
}

class _WorkshopProfileScreenState extends State<WorkshopProfileScreen> {
  late final WorkshopApiService _apiService;
  WorkshopModel? _workshop;
  bool _isLoading = true;
  bool _isSaving = false;

  bool _isOpen = true;
  Set<String> _services = {};
  Set<String> _vehicleTypes = {};

  @override
  void initState() {
    super.initState();
    _apiService = WorkshopApiService();
    _loadWorkshop();
  }

  Future<void> _loadWorkshop() async {
    try {
      final ws = await _apiService.getMyWorkshop();
      if (mounted) {
        setState(() {
          _workshop = ws;
          if (ws != null) {
            _isOpen = ws.isOpen;
            _services = Set.from(ws.services);
            _vehicleTypes = Set.from(ws.vehicleTypes);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_workshop == null) return;
    setState(() => _isSaving = true);
    try {
      final updated = await _apiService.updateWorkshop(_workshop!.id, {
        'isOpen': _isOpen,
        'services': _services.toList(),
        'vehicleTypes': _vehicleTypes.toList(),
      });
      if (mounted) {
        setState(() {
          _workshop = updated;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workshop profile saved!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save changes'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkBgGradient
              : const LinearGradient(
                  colors: [Color(0xFFF4F5F0), Color(0xFFECEDE8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Workshop',
                    style: GoogleFonts.rajdhani(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textLightPrimary)),
                const SizedBox(height: 20),
                
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                else if (_workshop == null)
                  const Center(child: Text('No workshop found.'))
                else ...[

                // Workshop header card
                GradientCard(
                  gradientColors: [
                    AppColors.primaryOrange.withValues(alpha: 0.15),
                    isDark
                        ? AppColors.darkCard
                        : AppColors.lightSurface,
                  ],
                  child: Column(
                    children: [
                      Row(children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppColors.orangeGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.store_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_workshop!.name,
                                  style: GoogleFonts.rajdhani(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textDarkPrimary
                                          : AppColors.textLightPrimary)),
                              Row(children: [
                                const Icon(Icons.star_rounded,
                                    size: 14,
                                    color: AppColors.warning),
                                const SizedBox(width: 3),
                                Text(_workshop!.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textDarkSecondary
                                            : AppColors.textLightSecondary)),
                                const SizedBox(width: 6),
                                Text('(${_workshop!.reviewCount} reviews)',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.textDarkMuted
                                            : AppColors.textLightMuted)),
                              ]),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isOpen,
                          onChanged: (v) => setState(() => _isOpen = v),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.primaryOrange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_workshop!.address}, ${_workshop!.city}, ${_workshop!.state} - ${_workshop!.pincode}',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textLightSecondary),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13,
                            color: AppColors.primaryOrange),
                        const SizedBox(width: 4),
                        Text('Mon–Sat: 9:00 AM – 7:00 PM', // Hardcoded for now
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textLightSecondary)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Vehicle types
                SectionHeader(title: 'Vehicle Types Served'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ['Car', 'Bike'].map((v) {
                    final sel = _vehicleTypes.contains(v);
                    return FilterChip(
                      label: Text(v),
                      selected: sel,
                      onSelected: (s) => setState(() =>
                          s ? _vehicleTypes.add(v) : _vehicleTypes.remove(v)),
                      selectedColor: AppColors.primaryOrange.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primaryOrange,
                      labelStyle: TextStyle(
                          color: sel
                              ? AppColors.primaryOrange
                              : (isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary),
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Services
                SectionHeader(title: 'Services Offered'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ServiceTypes.all.map((s) {
                    final sel = _services.contains(s);
                    return FilterChip(
                      label: Text(s),
                      selected: sel,
                      onSelected: (v) => setState(() =>
                          v ? _services.add(s) : _services.remove(s)),
                      selectedColor: AppColors.primaryOrange.withValues(alpha: 0.12),
                      checkmarkColor: AppColors.primaryOrange,
                      labelStyle: TextStyle(
                          fontSize: 12,
                          color: sel
                              ? AppColors.primaryOrange
                              : (isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.orangeGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save Changes',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
