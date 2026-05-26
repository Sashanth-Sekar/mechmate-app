import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'package:mechmate_app/features/owner/models/booking_model.dart';
import 'package:mechmate_app/shared/widgets/widgets.dart';

Future<void> showBookingDetailsSheet(
  BuildContext context,
  BookingModel booking,
  {required bool isDark, required Function(String status) onUpdateStatus}
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BookingDetailsSheet(booking: booking, isDark: isDark, onUpdateStatus: onUpdateStatus),
  );
}

class BookingDetailsSheet extends StatefulWidget {
  final BookingModel booking;
  final bool isDark;
  final Function(String status) onUpdateStatus;

  const BookingDetailsSheet({super.key, required this.booking, required this.isDark, required this.onUpdateStatus});

  @override
  State<BookingDetailsSheet> createState() => _BookingDetailsSheetState();
}

class _BookingDetailsSheetState extends State<BookingDetailsSheet> {
  bool _isUpdating = false;

  Future<void> _update(String newStatus) async {
    setState(() => _isUpdating = true);
    await widget.onUpdateStatus(newStatus);
    if (mounted) {
      setState(() => _isUpdating = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final fmt = DateFormat('EEEE, dd MMM yyyy • hh:mm a');

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                  ),
                ),
              ),
              StatusBadge(status: b.status),
            ],
          ),
          const SizedBox(height: 24),
          _buildRow(Icons.storefront, 'Workshop', b.workshopName),
          const SizedBox(height: 16),
          _buildRow(Icons.build_outlined, 'Service', b.service),
          const SizedBox(height: 16),
          _buildRow(Icons.directions_car_outlined, 'Vehicle', '${b.vehicleMake} ${b.vehicleModel} (${b.vehicleNumber})'),
          const SizedBox(height: 16),
          _buildRow(Icons.calendar_month_outlined, 'Scheduled For', fmt.format(b.scheduledAt)),
          const SizedBox(height: 16),
          _buildRow(Icons.history, 'Booked On', fmt.format(b.createdAt)),
          
          const SizedBox(height: 32),
          
          if (b.status == 'pending' || b.status == 'confirmed')
            SizedBox(
              width: double.infinity,
              height: 50,
              child: PrimaryButton(
                label: 'Cancel Booking',
                isLoading: _isUpdating,
                onPressed: () => _update('cancelled'),
                // You could change the button color to red here if PrimaryButton allows it,
                // otherwise it's just standard orange which is fine for now.
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryOrange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
