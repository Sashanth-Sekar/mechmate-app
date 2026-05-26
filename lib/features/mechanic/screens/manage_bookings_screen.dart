import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'package:mechmate_app/features/owner/models/booking_model.dart';
import 'package:mechmate_app/shared/services/services.dart';
import 'package:mechmate_app/shared/widgets/widgets.dart';

class ManageBookingsScreen extends StatefulWidget {
  final BookingApiService? bookingApiService;

  const ManageBookingsScreen({super.key, this.bookingApiService});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late final BookingApiService _apiService;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _apiService = widget.bookingApiService ?? BookingApiService();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (!ConnectivityService.instance.isOnline) {
      if (mounted) {
        setState(() {
        _error = 'No internet connection. Please go online to view bookings.';
        _isLoading = false;
      });
      }
      return;
    }

    setState(() { _error = null; _isLoading = true; });

    try {
      final res = await _apiService.getBookings();
      if (mounted) {
        setState(() {
          _bookings = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ManageBookingsScreen: load error — $e');
      if (mounted) {
        setState(() {
        _error = 'Failed to load bookings. Pull to retry.';
        _isLoading = false;
      });
      }
    }
  }

  Future<void> _updateStatus(String bookingId, String status) async {
    try {
      await _apiService.updateStatus(bookingId, status);
      await _loadBookings();
    } catch (e) {
      debugPrint('ManageBookingsScreen: status update error — $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update booking')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Widget _buildTabContent(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_error != null) {
      return ErrorRetry(
        message: _error!,
        onRetry: _loadBookings,
      );
    }

    if (_bookings.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today_rounded,
        title: 'No Bookings Found',
        subtitle: 'You have no booking requests yet.',
      );
    }

    return TabBarView(
      controller: _tabCtrl,
      children: [
        _BookingTabView(
          isDark: isDark,
          status: 'pending',
          bookings: _bookings.where((b) => b.status == 'pending').toList(),
          onUpdateStatus: _updateStatus,
        ),
        _BookingTabView(
          isDark: isDark,
          status: 'confirmed',
          bookings: _bookings
              .where((b) => b.status == 'confirmed' || b.status == 'active')
              .toList(),
          onUpdateStatus: _updateStatus,
        ),
        _BookingTabView(
          isDark: isDark,
          status: 'completed',
          bookings: _bookings
              .where((b) => b.status == 'completed' || b.status == 'cancelled')
              .toList(),
          onUpdateStatus: _updateStatus,
        ),
      ],
    );
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
                    Text('Bookings',
                        style: GoogleFonts.rajdhani(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textLightPrimary)),
                    const SizedBox(height: 14),
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
                        unselectedLabelColor: _error != null
                            ? Colors.grey
                            : isDark
                                ? AppColors.textDarkMuted
                                : AppColors.textLightMuted,
                        labelStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        tabs: const [
                          Tab(text: 'Pending'),
                          Tab(text: 'Confirmed'),
                          Tab(text: 'Completed'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              Expanded(child: _buildTabContent(isDark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingTabView extends StatelessWidget {
  final bool isDark;
  final String status;
  final List<BookingModel> bookings;
  final Function(String, String) onUpdateStatus;

  const _BookingTabView({
    required this.isDark,
    required this.status,
    required this.bookings,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Text('No $status bookings here.',
            style: TextStyle(
                color: isDark
                    ? AppColors.textDarkMuted
                    : AppColors.textLightMuted)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _MBookingCard(
        isDark: isDark,
        data: bookings[i],
        onUpdateStatus: (newStatus) =>
            onUpdateStatus(bookings[i].id, newStatus),
      ),
    );
  }
}

class _MBookingCard extends StatelessWidget {
  final bool isDark;
  final BookingModel data;
  final Function(String) onUpdateStatus;

  const _MBookingCard(
      {required this.isDark, required this.data, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('hh:mm a');
    final status = data.status;

    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.12),
              child: Text('U',
                  style: const TextStyle(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textDarkPrimary
                              : AppColors.textLightPrimary)),
                  Text('${data.service} · ${data.vehicleMake} ${data.vehicleModel}',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textLightMuted)),
                ],
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusBadge(status: status),
              const SizedBox(height: 4),
              Text(fmt.format(data.scheduledAt),
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textDarkMuted
                          : AppColors.textLightMuted)),
            ]),
          ]),
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => onUpdateStatus('cancelled'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reject',
                        style:
                            TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => onUpdateStatus('confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accept',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ),
            ]),
          ] else if (status == 'confirmed' || status == 'active') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: () => onUpdateStatus('completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyanAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Mark Completed',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
