// Fake BookingApiService for widget tests.
//
// Returns mock booking data without any network or Firebase dependency.
// Uses `implements` because the real constructor requires a non-mock
// [ApiClient].

import 'package:mechmate_app/features/owner/models/booking_model.dart';
import 'package:mechmate_app/shared/services/services.dart';

// ===================================================================
// Fake BookingApiService
// ===================================================================

/// Fake implementation of [BookingApiService] that returns mock booking data
/// without any network or Firebase dependency.  Uses `implements` instead of
/// `extends` because the real constructor requires a non-mock [ApiClient].
class FakeBookingApiService implements BookingApiService {
  List<BookingModel> _bookings = [];

  // Per-method error messages. When non-null the corresponding method
  // throws [ApiException] with that message on every invocation.
  String? _getErrorMessage;
  String? _createErrorMessage;
  String? _updateErrorMessage;
  String? _cancelErrorMessage;

  int getBookingsCallCount = 0;
  int createBookingCallCount = 0;
  int updateStatusCallCount = 0;
  int cancelBookingCallCount = 0;

  /// Configure which bookings to return from [getBookings].
  void setBookings(List<BookingModel> bookings) {
    _bookings = bookings;
  }

  /// [getBookings] will throw [ApiException] with [message].
  void setGetFailure(String message) {
    _getErrorMessage = message;
  }

  /// [createBooking] will throw [ApiException] with [message].
  void setCreateFailure(String message) {
    _createErrorMessage = message;
  }

  /// [updateStatus] will throw [ApiException] with [message].
  void setUpdateFailure(String message) {
    _updateErrorMessage = message;
  }

  /// [cancelBooking] will throw [ApiException] with [message].
  void setCancelFailure(String message) {
    _cancelErrorMessage = message;
  }

  /// Reset all methods back to success mode.
  void clearFailures() {
    _getErrorMessage = null;
    _createErrorMessage = null;
    _updateErrorMessage = null;
    _cancelErrorMessage = null;
  }

  @override
  Future<List<BookingModel>> getBookings({String? status}) async {
    getBookingsCallCount++;
    if (_getErrorMessage != null) {
      throw ApiException(_getErrorMessage!);
    }
    if (status != null) {
      return List.unmodifiable(
        _bookings.where((b) => b.status == status).toList(),
      );
    }
    return List.unmodifiable(_bookings);
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    createBookingCallCount++;
    if (_createErrorMessage != null) {
      throw ApiException(_createErrorMessage!);
    }
    _bookings = [..._bookings, booking];
    return booking;
  }

  @override
  Future<BookingModel> updateStatus(String bookingId, String status) async {
    updateStatusCallCount++;
    if (_updateErrorMessage != null) {
      throw ApiException(_updateErrorMessage!);
    }
    _bookings = _bookings.map((b) {
      if (b.id == bookingId) {
        return b.copyWith(status: status);
      }
      return b;
    }).toList();
    final updated = _bookings.firstWhere((b) => b.id == bookingId);
    return updated;
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    cancelBookingCallCount++;
    if (_cancelErrorMessage != null) {
      throw ApiException(_cancelErrorMessage!);
    }
    _bookings = _bookings.map((b) {
      if (b.id == bookingId) {
        return b.copyWith(status: 'cancelled');
      }
      return b;
    }).toList();
  }
}
