import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'package:mechmate_app/features/auth/providers/auth_provider.dart';
import 'package:mechmate_app/features/owner/models/booking_model.dart';
import 'package:mechmate_app/features/mechanic/models/workshop_model.dart';
import 'package:mechmate_app/shared/shared.dart';

class MechanicDashboardScreen extends StatefulWidget {
  const MechanicDashboardScreen({super.key});

  @override
  State<MechanicDashboardScreen> createState() =>
      _MechanicDashboardScreenState();
}

class _MechanicDashboardScreenState extends State<MechanicDashboardScreen> {
  late final WorkshopApiService _workshopApi;
  late final BookingApiService _bookingApi;

  WorkshopModel? _workshop;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _error;
  bool _isTogglingStatus = false;

  @override
  void initState() {
    super.initState();
    _workshopApi = WorkshopApiService();
    _bookingApi = BookingApiService();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!ConnectivityService.instance.isOnline) {
      if (mounted) {
        setState(() {
        _error = 'No internet connection.';
        _isLoading = false;
      });
      }
      return;
    }

    setState(() { _error = null; _isLoading = true; });

    try {
      final ws = await _workshopApi.getMyWorkshop();
      final bk = await _bookingApi.getBookings();
      if (mounted) {
        setState(() {
          _workshop = ws;
          _bookings = bk;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('MechanicDashboardScreen: load error — $e');
      if (mounted) {
        setState(() {
        _error = 'Failed to load data. Pull down to retry.';
        _isLoading = false;
      });
      }
    }
  }

  Future<void> _toggleStatus(bool isOpen) async {
    if (_workshop == null) return;
    setState(() => _isTogglingStatus = true);
    try {
      await _workshopApi.updateStatus(_workshop!.id, isOpen);
      setState(() {
        _workshop = _workshop!.copyWith(isOpen: isOpen);
      });
    } catch (e) {
      debugPrint('MechanicDashboardScreen: toggle status error — $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
      }
    } finally {
      if (mounted) setState(() => _isTogglingStatus = false);
    }
  }

  Future<void> _updateBookingStatus(String id, String status) async {
    try {
      await _bookingApi.updateStatus(id, status);
      await _loadData();
    } catch (e) {
      debugPrint('MechanicDashboardScreen: update booking status error — $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update booking')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();
    final name = auth.userModel?.name ?? 'Mechanic';

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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
              : _error != null
                  ? ErrorRetry(message: _error!, onRetry: () {
                      setState(() { _isLoading = true; _error = null; });
                      _loadData();
                    })
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dashboard',
                              style: GoogleFonts.rajdhani(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textDarkPrimary
                                    : AppColors.textLightPrimary,
                              )),
                          Text('Welcome back, ${name.split(' ').first}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textLightSecondary,
                              )),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.cyanAccent,
                      child: Text(
                        name[0].toUpperCase(),
                        style: GoogleFonts.rajdhani(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Workshop Status Toggle
                if (_workshop != null)
                  GradientCard(
                    gradientColors: _workshop!.isOpen
                        ? [
                            AppColors.success.withValues(alpha: 0.15),
                            AppColors.success.withValues(alpha: 0.05)
                          ]
                        : null,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (_workshop!.isOpen ? AppColors.success : AppColors.error)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _workshop!.isOpen ? Icons.store_rounded : Icons.store_mall_directory_outlined,
                            color: _workshop!.isOpen ? AppColors.success : AppColors.error,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workshop Status',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textDarkMuted
                                      : AppColors.textLightMuted,
                                ),
                              ),
                              Text(
                                _workshop!.isOpen ? 'Open — Accepting Bookings' : 'Closed',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _workshop!.isOpen
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontFamily: 'Rajdhani',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isTogglingStatus)
                          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          Switch(
                            value: _workshop!.isOpen,
                            onChanged: _toggleStatus,
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Today's Stats
                SectionHeader(title: "Today's Stats"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Bookings',
                        value: '${_bookings.length}',
                        icon: Icons.calendar_month_rounded,
                        color: AppColors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'Active Jobs',
                        value: '${_bookings.where((b) => b.status == 'confirmed' || b.status == 'active').length}',
                        icon: Icons.work_rounded,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'Revenue',
                        value: '₹—', // Mock for now, would be calculated from completed jobs
                        icon: Icons.currency_rupee_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pending Requests
                SectionHeader(title: 'Pending Requests', action: 'View All'),
                const SizedBox(height: 12),
                ..._pendingBookings(isDark),
                const SizedBox(height: 24),

                // Active Jobs
                SectionHeader(title: 'Active Jobs', action: 'View All'),
                const SizedBox(height: 12),                    ..._activeJobs(isDark),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  List<Widget> _pendingBookings(bool isDark) {
    final pending = _bookings.where((b) => b.status == 'pending').toList();
    if (pending.isEmpty) return [const Text('No pending requests')];
    return pending.take(3).map((b) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _PendingCard(
        isDark: isDark,
        booking: b,
        onUpdate: (status) => _updateBookingStatus(b.id, status),
      ),
    )).toList();
  }

  List<Widget> _activeJobs(bool isDark) {
    final active = _bookings.where((b) => b.status == 'confirmed' || b.status == 'active').toList();
    if (active.isEmpty) return [const Text('No active jobs')];
    return active.take(3).map((b) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _ActiveJobCard(
        isDark: isDark,
        booking: b,
        onUpdate: (status) => _updateBookingStatus(b.id, status),
      ),
    )).toList();
  }
}

class _PendingCard extends StatelessWidget {
  final bool isDark;
  final BookingModel booking;
  final Function(String) onUpdate;

  const _PendingCard({
    required this.isDark,
    required this.booking,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, dd MMM hh:mm a');
    return GradientCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
                child: const Text(
                  'U',
                  style: TextStyle(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer', // Should be owner name
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textLightPrimary)),
                    Text('${booking.vehicleMake} ${booking.vehicleModel} · ${booking.vehicleNumber}',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textDarkMuted
                                : AppColors.textLightMuted)),
                  ],
                ),
              ),
              StatusBadge(status: 'pending'),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.build_outlined,
                size: 13,
                color: isDark
                    ? AppColors.textDarkMuted
                    : AppColors.textLightMuted),
            const SizedBox(width: 5),
            Text(booking.service,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary)),
            const SizedBox(width: 12),
            Icon(Icons.access_time_rounded,
                size: 13,
                color: isDark
                    ? AppColors.textDarkMuted
                    : AppColors.textLightMuted),
            const SizedBox(width: 5),
            Text(fmt.format(booking.scheduledAt),
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () => onUpdate('cancelled'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Reject',
                      style: TextStyle(
                          color: AppColors.error, fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () => onUpdate('confirmed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Accept',
                      style: TextStyle(
                          color: Colors.white, fontSize: 12)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  final bool isDark;
  final BookingModel booking;
  final Function(String) onUpdate;

  const _ActiveJobCard({
    required this.isDark,
    required this.booking,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cyanAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_rounded,
                color: AppColors.cyanAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(booking.service,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textDarkPrimary
                              : AppColors.textLightPrimary)),
                  const Spacer(),
                  Text(booking.status.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 3),
                Text('${booking.vehicleMake} ${booking.vehicleModel} · ${booking.vehicleNumber}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textLightMuted)),
                const SizedBox(height: 5),
                Text(DateFormat('hh:mm a').format(booking.scheduledAt),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onUpdate('completed'),
            icon: const Icon(Icons.check_circle_outline_rounded),
            color: AppColors.success,
            tooltip: 'Mark Completed',
          ),
        ],
      ),
    );
  }
}
