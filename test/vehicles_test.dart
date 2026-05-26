// Widget tests for the vehicle management screens (MyVehiclesScreen).
//
// Covers:
//   1. Loading indicator on initial render
//   2. Empty state when no vehicles exist
//   3. Error state with Retry button
//   4. Vehicle list display with correct data
//   5. Add vehicle via bottom sheet (success)
//   6. Error snackbar when adding vehicle fails
//   7. Delete vehicle via popup menu
//
// Google Fonts is disabled via allowRuntimeFetching=false (fonts are
// bundled under assets/fonts/).
//
// pumpAndSettle() is deliberately avoided — animations may time out.

import 'package:mechmate_app/features/owner/owner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';


import 'test_utils.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // ---------------------------------------------------------------
  // MyVehiclesScreen
  // ---------------------------------------------------------------
  group('MyVehiclesScreen', () {
    testWidgets('shows loading indicator initially, then renders content',
        (WidgetTester tester) async {
      final api = FakeVehicleApiService();

      await tester.pumpWidget(
        wrapApp(MyVehiclesScreen(vehicleApiService: api)),
      );

      // _loadVehicles is async — initially isLoading is true
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let the load complete
      await settleAsync(tester);

      // Now shows empty state (no vehicles configured)
      expect(find.text('No vehicles added yet'), findsOneWidget);
      expect(api.getVehiclesCallCount, equals(1));
    });

    testWidgets('shows empty state when no vehicles exist',
        (WidgetTester tester) async {
      final api = FakeVehicleApiService()..setVehicles([]);

      await tester.pumpWidget(
        wrapApp(MyVehiclesScreen(vehicleApiService: api)),
      );
      await settleAsync(tester);

      expect(find.text('No vehicles added yet'), findsOneWidget);
      // FAB should be visible
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('shows error state with Retry button that recovers on success',
        (WidgetTester tester) async {
      final api = FakeVehicleApiService()
        ..setGetFailure('Unable to load vehicles right now.');

      await tester.pumpWidget(
        wrapApp(MyVehiclesScreen(vehicleApiService: api)),
      );
      await settleAsync(tester);

      // Error state
      expect(find.text('Unable to load vehicles right now.'), findsOneWidget);
      expect(findPrimaryButton('Retry'), findsOneWidget);

      // Tap Retry while still in failure mode — stays in error
      await tester.tap(findPrimaryButton('Retry'));
      await settleAsync(tester);
      expect(find.text('Unable to load vehicles right now.'), findsOneWidget);

      // Switch to success and retry
      api.clearFailures();
      api.setVehicles([]);
      await tester.tap(findPrimaryButton('Retry'));
      await settleAsync(tester);

      // Now shows empty state
      expect(find.text('No vehicles added yet'), findsOneWidget);
      expect(api.getVehiclesCallCount, equals(3)); // initial + 2 retries
    });

    testWidgets('displays vehicle list with correct data',
        (WidgetTester tester) async {
      final vehicles = [
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
      final api = FakeVehicleApiService()..setVehicles(vehicles);

      await tester.pumpWidget(
        wrapApp(MyVehiclesScreen(vehicleApiService: api)),
      );
      await settleAsync(tester);

      // Titles
      expect(find.text('Hyundai i20'), findsOneWidget);
      expect(find.text('Royal Enfield Classic 350'), findsOneWidget);

      // Number badges
      expect(find.text('MH12AB1234'), findsOneWidget);
      expect(find.text('MH22XY7890'), findsOneWidget);

      // Detail rows — year
      expect(find.text('2022'), findsOneWidget);
      expect(find.text('2021'), findsOneWidget);

      // Detail rows — color
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Black'), findsOneWidget);

      // Detail rows — type
      expect(find.text('Car'), findsOneWidget);
      expect(find.text('Bike'), findsOneWidget);

      // "Active" counter not shown for vehicles
      expect(find.text('No vehicles added yet'), findsNothing);
    });

    testWidgets('adds vehicle via bottom sheet and shows success snackbar',
        (WidgetTester tester) async {
      final api = FakeVehicleApiService()..setVehicles([]);

      await tester.pumpWidget(
        wrapApp(MyVehiclesScreen(vehicleApiService: api)),
      );
      await settleAsync(tester);

      // Starts empty
      expect(find.text('No vehicles added yet'), findsOneWidget);

      // Tap the FAB to open the Add Vehicle bottom sheet
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // sheet animation

      // Sheet title
      expect(find.text('Add Vehicle'), findsWidgets); // both title + FAB label

      // Fill the form (Vehicle Number is required, Make & Model are required,
      // Year is optional with validation, Color is optional)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Vehicle Number'),
        'MH12AB1234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Make'),
        'Hyundai',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Model'),
        'i20',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Year'),
        '2022',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Color'),
        'Blue',
      );
      await settleAsync(tester);

      // Default type is 'Car' (already selected)
      // Note: findsWidgets means at least 1 — Car appears in the toggle
      // but may also appear as the type detail in a card (once added).
      expect(find.text('Car'), findsAtLeast(1));

      // Tap Add Vehicle in the bottom sheet
      await tester.tap(findPrimaryButton('Add Vehicle'));
      // Pump enough frames for the sheet to fully animate out, then let
      // the async addVehicle call settle.
      await pumpForRoute(tester);
      await settleAsync(tester);

      // SnackBar shows success
      expect(find.text('Vehicle added.'), findsOneWidget);

      // Vehicle appears in the list
      expect(find.text('Hyundai i20'), findsOneWidget);
      expect(find.text('MH12AB1234'), findsOneWidget);

      // API was called
      expect(api.addVehicleCallCount, equals(1));
    });

    testWidgets('shows error snackbar when adding vehicle fails',
        (WidgetTester tester) async {
      final api = FakeVehicleApiService()..setVehicles([]);

      await tester.pumpWidget(
        wrapApp(MyVehiclesScreen(vehicleApiService: api)),
      );
      await settleAsync(tester);

      // Initial load succeeded — empty state shown
      expect(find.text('No vehicles added yet'), findsOneWidget);

      // Now configure failure for the add attempt
      api.setAddFailure('Unable to save vehicle. Please try again.');

      // Tap FAB to open sheet
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Fill required fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Vehicle Number'),
        'MH99XX9999',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Make'),
        'Honda',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Model'),
        'City',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Year'),
        '2023',
      );
      await settleAsync(tester);

      // Tap Add Vehicle
      await tester.tap(findPrimaryButton('Add Vehicle'));
      // Pump frames for sheet to animate out, then settle async work
      await pumpForRoute(tester);
      await settleAsync(tester);

      // Error snackbar — use descendant finder to avoid matching stale
      // text from the sheet's exit animation
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Unable to save vehicle. Please try again.'),
        ),
        findsOneWidget,
      );

      // List is still empty
      expect(find.text('No vehicles added yet'), findsOneWidget);
      expect(api.addVehicleCallCount, equals(1));
    });

    testWidgets('deletes vehicle via popup menu',
        (WidgetTester tester) async {
      final vehicle = VehicleModel(
        id: 'v1',
        type: 'Car',
        number: 'MH12AB1234',
        make: 'Hyundai',
        model: 'i20',
        year: 2022,
        color: 'Blue',
      );
      final api = FakeVehicleApiService()..setVehicles([vehicle]);

      await tester.pumpWidget(
        wrapApp(MyVehiclesScreen(vehicleApiService: api)),
      );
      await settleAsync(tester);

      // Vehicle is visible
      expect(find.text('Hyundai i20'), findsOneWidget);

      // Tap the popup menu (more_vert icon)
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // popup animation

      // Tap Delete in the popup
      await tester.tap(find.text('Delete').last);
      await settleAsync(tester);

      // Vehicle removed from list
      expect(find.text('Hyundai i20'), findsNothing);
      expect(find.text('No vehicles added yet'), findsOneWidget);

      // API was called
      expect(api.deleteVehicleCallCount, equals(1));
    });
  });
}
