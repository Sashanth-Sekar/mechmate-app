import 'package:mechmate_app/features/owner/owner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'package:mechmate_app/shared/shared.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late final BookingApiService _apiService;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _apiService = BookingApiService();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!ConnectivityService.instance.isOnline) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'No internet connection. Please check your network.';
        });
        return;
      }

      final res = await _apiService.getBookings().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ApiException('Request timed out'),
      );
      if (!mounted) return;
      setState(() {
        _bookings = res;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('BookingsApi: getBookings failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is ApiException
            ? e.message
            : 'Unable to load bookings right now.';
      });
    }
  }

  Future<void> _updateStatus(String bookingId, String status) async {
    try {
      await _apiService.updateStatus(bookingId, status);
      await _loadBookings();
    } catch (e) {
      debugPrint('BookingsApi: updateStatus failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e is ApiException ? e.message : 'Failed to update booking',
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Bookings',
                      style: GoogleFonts.rajdhani(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textLightPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicator: BoxDecoration(
                          gradient: AppColors.orangeGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textLightMuted,
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Active'),
                          Tab(text: 'Upcoming'),
                          Tab(text: 'History'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
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
                Icons.cloud_off_rounded,
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
                onPressed: _loadBookings,
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabCtrl,
      children: [
        _BookingList(
          isDark: isDark,
          bookings: _bookings
              .where((b) => b.status == 'pending' || b.status == 'active')
              .toList(),
          onUpdateStatus: _updateStatus,
          onRefresh: _loadBookings,
        ),
        _BookingList(
          isDark: isDark,
          bookings: _bookings
              .where((b) => b.status == 'confirmed')
              .toList(),
          onUpdateStatus: _updateStatus,
          onRefresh: _loadBookings,
        ),
        _BookingList(
          isDark: isDark,
          bookings: _bookings
              .where((b) =>
                  b.status == 'completed' || b.status == 'cancelled')
              .toList(),
          onUpdateStatus: _updateStatus,
          onRefresh: _loadBookings,
        ),
      ],
    );
  }
}

class _BookingList extends StatelessWidget {
  final bool isDark;
  final List<BookingModel> bookings;
  final Function(String, String) onUpdateStatus;
  final Future<void> Function()? onRefresh;

  const _BookingList({
    required this.isDark,
    required this.bookings,
    required this.onUpdateStatus,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 56,
              color: isDark
                  ? AppColors.textDarkMuted
                  : AppColors.textLightMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No bookings yet',
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
      onRefresh: onRefresh ?? () async {},
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        itemCount: bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _BookingCard(
          isDark: isDark,
          data: bookings[i],
          onTap: () {
            showBookingDetailsSheet(
              context,
              bookings[i],
              isDark: isDark,
              onUpdateStatus: (newStatus) =>
                  onUpdateStatus(bookings[i].id, newStatus),
            );
          },
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final bool isDark;
  final BookingModel data;
  final VoidCallback onTap;

  const _BookingCard({
    required this.isDark,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    return GestureDetector(
      onTap: onTap,
      child: GradientCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.workshopName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Rajdhani',
                      color: isDark
                          ? AppColors.textDarkPrimary
                          : AppColors.textLightPrimary,
                    ),
                  ),
                ),
                StatusBadge(status: data.status),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(Icons.build_outlined, data.service, isDark),
            const SizedBox(height: 6),
            _InfoRow(
              Icons.directions_car_outlined,
              '${data.vehicleMake} ${data.vehicleModel} · ${data.vehicleNumber}',
              isDark,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              Icons.access_time_rounded,
              fmt.format(data.scheduledAt),
              isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _InfoRow(this.icon, this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textLightSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
