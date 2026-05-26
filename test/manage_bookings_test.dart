// Widget tests for the ManageBookingsScreen (mechanic's booking management).
//
// Covers:
//   1. Loading indicator on initial render
//   2. Transitions from loading to empty state
//   3. Tab headers rendered (Pending, Confirmed, Completed)
//   4. Empty tab content messages (with non-empty bookings list)
//   5. Booking list display with correct data
//   6. Accept button calls updateStatus with 'confirmed'
//   7. Reject button calls updateStatus with 'cancelled'
//   8. Mark Completed button calls updateStatus with 'completed'
//   9. Error state with Retry button
//
// Google Fonts is disabled via allowRuntimeFetching=false.
// pumpAndSettle() is deliberately avoided — animations may time out.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mechmate_app/features/mechanic/screens/manage_bookings_screen.dart';
import 'package:mechmate_app/features/owner/models/booking_model.dart';
import 'package:mechmate_app/shared/widgets/widgets.dart';

import 'test_utils.dart';

// ===================================================================
// Sample data
// ===================================================================

final _now = DateTime.now();

final _pendingBooking = BookingModel(
  id: 'b1',
  ownerId: 'owner-1',
  workshopId: 'ws-1',
  workshopName: 'Speed Garage',
  service: 'Oil Change',
  vehicleType: 'Car',
  vehicleNumber: 'MH12AB1234',
  vehicleMake: 'Hyundai',
  vehicleModel: 'i20',
  scheduledAt: _now,
  status: 'pending',
  createdAt: _now,
);

final _confirmedBooking = BookingModel(
  id: 'b2',
  ownerId: 'owner-2',
  workshopId: 'ws-1',
  workshopName: 'Speed Garage',
  service: 'AC Service',
  vehicleType: 'Car',
  vehicleNumber: 'MH34CD5678',
  vehicleMake: 'Honda',
  vehicleModel: 'City',
  scheduledAt: _now,
  status: 'confirmed',
  createdAt: _now,
);



// ===================================================================
// Tests
// ===================================================================

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('ManageBookingsScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final api = FakeBookingApiService();

      await tester.pumpWidget(
        wrapApp(ManageBookingsScreen(bookingApiService: api)),
      );

      // _loadBookings is async — initially isLoading is true so
      // CircularProgressIndicator is rendered inside _buildTabContent.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let the load complete so the test ends cleanly.
      await settleAsync(tester);
    });

    testWidgets('transitions from loading to empty state', (tester) async {
      final api = FakeBookingApiService();

      await tester.pumpWidget(
        wrapApp(ManageBookingsScreen(bookingApiService: api)),
      );

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let the load complete
      await settleAsync(tester);

      // Empty state shown
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No Bookings Found'), findsOneWidget);
      expect(find.text('You have no booking requests yet.'), findsOneWidget);

      // Tab names are visible
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      expect(api.getBookingsCallCount, equals(1));
    });

    testWidgets('shows empty tab content for each tab', (tester) async {
      // Use only a confirmed booking so the list is non-empty but the
      // Pending tab's filtered list is empty (showing per-tab empty text).
      final api = FakeBookingApiService()
        ..setBookings([_confirmedBooking]);

      await tester.pumpWidget(
        wrapApp(ManageBookingsScreen(bookingApiService: api)),
      );
      await settleAsync(tester);

      // Pending tab is selected by default — shows "No pending bookings here."
      // because the empty-state logic only shows EmptyState when _bookings
      // is completely empty; otherwise it shows TabBarView with per-tab text.
      expect(find.text('No pending bookings here.'), findsOneWidget);

      // Switch to Confirmed tab — shows the confirmed booking card
      await tester.tap(find.text('Confirmed').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('AC Service'), findsOneWidget);

      // Switch to Completed tab — shows "No completed bookings here."
      await tester.tap(find.text('Completed').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('No completed bookings here.'), findsOneWidget);
    });

    testWidgets('displays booking cards with correct data', (tester) async {
      final api = FakeBookingApiService()
        ..setBookings([_pendingBooking]);

      await tester.pumpWidget(
        wrapApp(ManageBookingsScreen(bookingApiService: api)),
      );
      await settleAsync(tester);

      // Pending tab is default — shows the pending booking
      expect(find.textContaining('Oil Change'), findsOneWidget);
      expect(find.textContaining('Hyundai i20'), findsOneWidget);

      // Customer avatar 'U'
      expect(find.text('U'), findsOneWidget);

      // Accept / Reject buttons for pending status
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('Accept button calls updateStatus with confirmed',
        (tester) async {
      final api = FakeBookingApiService()
        ..setBookings([_pendingBooking]);

      await tester.pumpWidget(
        wrapApp(ManageBookingsScreen(bookingApiService: api)),
      );
      await settleAsync(tester);

      // Tap Accept
      await tester.tap(find.text('Accept'));
      await settleAsync(tester);

      expect(api.updateStatusCallCount, equals(1));
      // After accepting, the pending booking is updated — the tab view
      // filters by status so it should now show empty pending tab.
      expect(find.text('No pending bookings here.'), findsOneWidget);
    });

    testWidgets('Reject button calls updateStatus with cancelled',
        (tester) async {
      final api = FakeBookingApiService()
        ..setBookings([_pendingBooking]);

      await tester.pumpWidget(
        wrapApp(ManageBookingsScreen(bookingApiService: api)),
      );
      await settleAsync(tester);

      // Tap Reject
      await tester.tap(find.text('Reject'));
      await settleAsync(tester);

      expect(api.updateStatusCallCount, equals(1));
      expect(find.text('No pending bookings here.'), findsOneWidget);
    });

    testWidgets('Mark Completed button calls updateStatus with completed',
        (tester) async {
      final api = FakeBookingApiService()
        ..setBookings([_confirmedBooking]);

      await tester.pumpWidget(
        wrapApp(ManageBookingsScreen(bookingApiService: api)),
      );
      await settleAsync(tester);

      // Switch to Confirmed tab
      await tester.tap(find.text('Confirmed').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Mark Completed (use .last since TabBarView keeps all tabs'
      // children mounted, there could be a stale "Mark Completed" from
      // a pending → confirmed transition)
      await tester.tap(find.text('Mark Completed').last);
      await settleAsync(tester);

      expect(api.updateStatusCallCount, equals(1));
    });

    testWidgets('shows error state with Retry button', (tester) async {
      final api = FakeBookingApiService()
        ..setGetFailure('Failed to load bookings. Pull to retry.');

      await tester.pumpWidget(
        wrapApp(ManageBookingsScreen(bookingApiService: api)),
      );
      await settleAsync(tester);

      // ErrorRetry widget shown — message is wrapped in a Text
      expect(find.text('Failed to load bookings. Pull to retry.'),
          findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tab labels should still be visible
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Tap retry while still failing — stays in error
      await tester.tap(find.text('Try Again'));
      await settleAsync(tester);
      expect(find.text('Failed to load bookings. Pull to retry.'),
          findsOneWidget);
      expect(api.getBookingsCallCount, equals(2)); // initial + retry

      // Switch to success and retry
      api.clearFailures();
      api.setBookings([_pendingBooking]);
      await tester.tap(find.text('Try Again'));
      await settleAsync(tester);

      // Now shows the pending booking
      expect(find.textContaining('Oil Change'), findsOneWidget);
      expect(api.getBookingsCallCount, equals(3));
    });
  });
}
