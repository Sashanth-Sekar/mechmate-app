import 'package:mechmate_app/features/owner/models/booking_model.dart';
import 'package:mechmate_app/shared/services/api_client.dart';

class BookingApiService {
  final ApiClient _client;

  /// Uses the global [ApiClient.instance] singleton by default.
  BookingApiService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Fetch all bookings for the current user (owner sees their bookings,
  /// mechanic sees their workshop's bookings).
  Future<List<BookingModel>> getBookings({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    return _client.getList(
      '/bookings$query',
      fromJson: (data) => BookingModel.fromMap(data),
    );
  }

  /// Create a new booking.
  Future<BookingModel> createBooking(BookingModel booking) async {
    return _client.post(
      '/bookings',
      body: booking.toMap()..remove('id'),
      fromJson: (data) => BookingModel.fromMap(data),
    );
  }

  /// Update booking status (confirm, reject, complete, cancel).
  Future<BookingModel> updateStatus(String bookingId, String status) async {
    final result = await _client.patch<Map<String, dynamic>>(
      '/bookings/$bookingId/status',
      body: {'status': status},
      fromJson: (data) => data,
    );
    return BookingModel.fromMap(result!);
  }

  /// Cancel a booking.
  Future<void> cancelBooking(String bookingId) async {
    await _client.patch<void>(
      '/bookings/$bookingId/status',
      body: {'status': 'cancelled'},
    );
  }
}
