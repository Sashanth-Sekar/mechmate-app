import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/features/owner/models/vehicle_model.dart';
import 'package:mechmate_app/shared/shared.dart';

class MyVehiclesScreen extends StatefulWidget {
  /// Optional service injection for testing. If omitted, uses
  /// [VehicleApiService] with the default [ApiClient.instance] singleton.
  final VehicleApiService? vehicleApiService;

  const MyVehiclesScreen({super.key, this.vehicleApiService});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  late final VehicleApiService _vehicleApi;

  List<VehicleModel> _vehicles = const [];
  bool _didLoad = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _initApi();
      _loadVehicles();
    }
  }

  void _initApi() {
    _vehicleApi = widget.vehicleApiService ?? VehicleApiService();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicles = await _vehicleApi.getVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('VehicleApi: getVehicles failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            e is ApiException ? e.message : 'Unable to load vehicles right now.';
      });
    }
  }

  Future<void> _showAddVehicle(BuildContext context) async {
    final vehicle = await showModalBottomSheet<VehicleModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddVehicleSheet(),
    );

    if (vehicle == null || !mounted) return;
    await _addVehicle(vehicle);
  }

  Future<void> _addVehicle(VehicleModel vehicle) async {
    try {
      final created = await _vehicleApi.addVehicle(vehicle);
      if (!mounted) return;
      setState(() {
        _vehicles = [..._vehicles.where((v) => v.id != created.id), created];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle added.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('VehicleApi: addVehicle failed: $e');
      if (!mounted) return;
      final msg = e is ApiException
          ? e.message
          : 'Unable to save vehicle. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteVehicle(VehicleModel vehicle) async {
    try {
      await _vehicleApi.deleteVehicle(vehicle.id);
      if (!mounted) return;
      setState(() {
        _vehicles = _vehicles.where((v) => v.id != vehicle.id).toList();
      });
    } catch (e) {
      debugPrint('VehicleApi: deleteVehicle failed: $e');
      if (!mounted) return;
      final msg = e is ApiException
          ? e.message
          : 'Unable to delete vehicle. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicle(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Vehicle',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text(
                  'My Vehicles',
                  style: GoogleFonts.rajdhani(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textLightPrimary,
                  ),
                ),
              ),
              Expanded(child: _buildBody(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: isDark
                    ? AppColors.textDarkMuted
                    : AppColors.textLightMuted,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkMuted
                      : AppColors.textLightMuted,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Retry',
                width: 140,
                onPressed: _loadVehicles,
              ),
            ],
          ),
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 60,
              color: isDark
                  ? AppColors.textDarkMuted
                  : AppColors.textLightMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No vehicles added yet',
              style: TextStyle(
                color: isDark
                    ? AppColors.textDarkMuted
                    : AppColors.textLightMuted,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVehicles,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: _vehicles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _VehicleCard(
          isDark: isDark,
          data: _vehicles[i],
          onDelete: () => _deleteVehicle(_vehicles[i]),
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final bool isDark;
  final VehicleModel data;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.isDark,
    required this.data,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCar = data.type == 'Car';
    final color = data.color?.trim().isNotEmpty == true
        ? data.color!.trim()
        : 'Unknown';

    return GradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isCar
                      ? AppColors.orangeGradient
                      : AppColors.cyanGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCar
                      ? Icons.directions_car_rounded
                      : Icons.two_wheeler_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.make} ${data.model}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Rajdhani',
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textLightPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.number,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert_rounded,
                  color: isDark
                      ? AppColors.textDarkMuted
                      : AppColors.textLightMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              _Detail(label: 'Year', value: '${data.year}', isDark: isDark),
              _Detail(label: 'Color', value: color, isDark: isDark),
              _Detail(label: 'Type', value: data.type, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _Detail({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textDarkMuted
                  : AppColors.textLightMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textDarkPrimary
                  : AppColors.textLightPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddVehicleSheet extends StatefulWidget {
  const _AddVehicleSheet();

  @override
  State<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<_AddVehicleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String _type = 'Car';

  @override
  void dispose() {
    _numCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Vehicle',
              style: GoogleFonts.rajdhani(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: ['Car', 'Bike'].map((t) {
                final sel = _type == t;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: t == 'Car' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: sel ? AppColors.orangeGradient : null,
                          color: sel
                              ? null
                              : (isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? Colors.transparent
                                : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              t == 'Car'
                                  ? Icons.directions_car_rounded
                                  : Icons.two_wheeler_rounded,
                              size: 16,
                              color: sel
                                  ? Colors.white
                                  : AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t,
                              style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.textDarkPrimary
                                          : AppColors.textLightPrimary),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _numCtrl,
              label: 'Vehicle Number',
              prefixIcon: Icons.pin_outlined,
              validator: AppValidators.vehicleNumber,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _makeCtrl,
                    label: 'Make',
                    validator: (v) => AppValidators.required(v, field: 'Make'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    controller: _modelCtrl,
                    label: 'Model',
                    validator: (v) => AppValidators.required(v, field: 'Model'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _yearCtrl,
                    label: 'Year',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: AppValidators.year,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(controller: _colorCtrl, label: 'Color'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Add Vehicle',
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;

                final number = _numCtrl.text.trim().toUpperCase();
                Navigator.pop(
                  context,
                  VehicleModel(
                    id: number.replaceAll(RegExp(r'\s+'), ''),
                    type: _type,
                    number: number,
                    make: _makeCtrl.text.trim(),
                    model: _modelCtrl.text.trim(),
                    year:
                        int.tryParse(_yearCtrl.text.trim()) ??
                        DateTime.now().year,
                    color: _colorCtrl.text.trim().isEmpty
                        ? null
                        : _colorCtrl.text.trim(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
