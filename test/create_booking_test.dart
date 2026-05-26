// Widget tests for the CreateBookingScreen (owner's booking creation form).
//
// Covers:
//   1. Loading state (CircularProgressIndicator for vehicle fetch)
//   2. Error state with Retry button
//   3. Empty vehicles message
//   4. Form renders with shop name, service chips, vehicle dropdown, schedule
//   5. Service selection via ChoiceChip
//   6. Vehicle selection via dropdown
//   7. Form validation — empty fields show snackbar
//
// Note: Full submission tests (including date/time picker interaction) are
// intentionally omitted because showDatePicker and showTimePicker use
// platform channels internally and are unreliable in widget test mode.
//
// Google Fonts is disabled via allowRuntimeFetching=false.

// ignore_for_file: prefer_const_constructors

import 'package:mechmate_app/features/owner/owner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';


import 'test_utils.dart';

// ===================================================================
// Sample data
// ===================================================================

final _shop = ShopModel(
  id: 'ws-1',
  name: 'Speed Garage',
  latitude: 18.5204,
  longitude: 73.8567,
  rating: 4.5,
  distance: 1.2,
  isOpen: true,
  services: ['Oil Change', 'Tire Rotation', 'AC Service'],
);

final _vehicles = [
  VehicleModel(
    id: 'v1',
    type: 'Car',
    number: 'MH12AB1234',
    make: 'Hyundai',
    model: 'i20',
    year: 2022,
    color: 'Blue',
  ),
  VehicleModel(
    id: 'v2',
    type: 'Bike',
    number: 'MH22XY7890',
    make: 'Royal Enfield',
    model: 'Classic 350',
    year: 2021,
    color: 'Black',
  ),
];

// ===================================================================
// Helpers
// ===================================================================

/// Wrap [child] in a MaterialApp so navigation APIs work.
Widget _wrapApp(Widget child) {
  return MaterialApp(home: child);
}

/// Build a [CreateBookingScreen] wired to the given [vehicleApi] and
/// [bookingApi] fakes.
Widget _buildScreen({
  required FakeVehicleApiService vehicleApi,
  required FakeBookingApiService bookingApi,
}) {
  return _wrapApp(
    CreateBookingScreen(
      shop: _shop,
      vehicleApiService: vehicleApi,
      bookingApiService: bookingApi,
    ),
  );
}

// ===================================================================
// Tests
// ===================================================================

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('CreateBookingScreen', () {
    testWidgets('shows loading indicator initially, then renders form',
        (tester) async {
      final vehicleApi = FakeVehicleApiService()..setVehicles(_vehicles);
      final bookingApi = FakeBookingApiService();

      await tester.pumpWidget(
        _buildScreen(vehicleApi: vehicleApi, bookingApi: bookingApi),
      );

      // Initially loading vehicles
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let the load complete
      await settleAsync(tester);

      // Shop name displayed
      expect(find.text('Speed Garage'), findsOneWidget);

      // Form sections
      expect(find.text('Select Service'), findsOneWidget);
      expect(find.text('Select Vehicle'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);

      // Service chips
      expect(find.text('Oil Change'), findsOneWidget);
      expect(find.text('Tire Rotation'), findsOneWidget);
      expect(find.text('AC Service'), findsOneWidget);

      // Vehicle dropdown shows first vehicle
      expect(find.text('Hyundai i20 (MH12AB1234)'), findsOneWidget);

      // Date/Time buttons
      expect(find.text('Select Date'), findsOneWidget);
      expect(find.text('Select Time'), findsOneWidget);

      // Submit button
      expect(find.text('Confirm Booking'), findsOneWidget);

      expect(vehicleApi.getVehiclesCallCount, equals(1));
    });

    testWidgets('shows error state with Retry that recovers', (tester) async {
      final vehicleApi = FakeVehicleApiService()
        ..setGetFailure('Failed to load vehicles');
      final bookingApi = FakeBookingApiService();

      await tester.pumpWidget(
        _buildScreen(vehicleApi: vehicleApi, bookingApi: bookingApi),
      );
      await settleAsync(tester);

      // Error state
      expect(find.text('Failed to load vehicles'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Retry while still failing
      await tester.tap(find.text('Try Again'));
      await settleAsync(tester);
      expect(find.text('Failed to load vehicles'), findsOneWidget);
      expect(vehicleApi.getVehiclesCallCount, equals(2));

      // Recover
      vehicleApi.clearFailures();
      vehicleApi.setVehicles(_vehicles);
      await tester.tap(find.text('Try Again'));
      await settleAsync(tester);

      // Form renders
      expect(find.text('Speed Garage'), findsOneWidget);
      expect(vehicleApi.getVehiclesCallCount, equals(3));
    });

    testWidgets('shows empty vehicles message when no vehicles exist',
        (tester) async {
      final vehicleApi = FakeVehicleApiService()..setVehicles([]);
      final bookingApi = FakeBookingApiService();

      await tester.pumpWidget(
        _buildScreen(vehicleApi: vehicleApi, bookingApi: bookingApi),
      );
      await settleAsync(tester);

      expect(
        find.text('No vehicles added. Please add one from My Vehicles.'),
        findsOneWidget,
      );
    });

    testWidgets('selects service via ChoiceChip', (tester) async {
      final vehicleApi = FakeVehicleApiService()..setVehicles(_vehicles);
      final bookingApi = FakeBookingApiService();

      await tester.pumpWidget(
        _buildScreen(vehicleApi: vehicleApi, bookingApi: bookingApi),
      );
      await settleAsync(tester);

      // Tap 'Tire Rotation' chip
      await tester.tap(find.text('Tire Rotation'));
      await tester.pump();

      // Tap 'Oil Change' chip
      await tester.tap(find.text('Oil Change'));
      await tester.pump();

      // Just verify no crash — selection is internal state
    });

    testWidgets('selects vehicle via dropdown', (tester) async {
      final vehicleApi = FakeVehicleApiService()..setVehicles(_vehicles);
      final bookingApi = FakeBookingApiService();

      await tester.pumpWidget(
        _buildScreen(vehicleApi: vehicleApi, bookingApi: bookingApi),
      );
      await settleAsync(tester);

      // Open the vehicle dropdown
      await tester.tap(find.text('Hyundai i20 (MH12AB1234)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Select the second vehicle (use .last because the dropdown button
      // and the open menu item may both be present in the tree)
      await tester.tap(find.text('Royal Enfield Classic 350 (MH22XY7890)').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Close the dropdown by tapping elsewhere before checking
      await tester.tapAt(const Offset(0, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify selection changed (now only the dropdown button shows it)
      expect(find.text('Royal Enfield Classic 350 (MH22XY7890)'), findsOneWidget);
    });

    testWidgets('shows validation snackbar when fields are empty',
        (tester) async {
      final vehicleApi = FakeVehicleApiService()..setVehicles(_vehicles);
      final bookingApi = FakeBookingApiService();

      await tester.pumpWidget(
        _buildScreen(vehicleApi: vehicleApi, bookingApi: bookingApi),
      );
      await settleAsync(tester);

      // Tap Confirm Booking without filling service, date, or time
      await tester.tap(find.text('Confirm Booking'));
      await tester.pump();

      // Validation snackbar appears
      expect(find.text('Please fill all fields'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      // createBooking was NOT called
      expect(bookingApi.createBookingCallCount, equals(0));
    });
  });
}
