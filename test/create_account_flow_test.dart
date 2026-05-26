// Widget test for the full Create Account flow.
//
// Starts from the Login Screen, taps the "Register" link to reach the
// RegisterOwnerScreen, fills account details + geo selector, and submits
// via the "Create Account" button on Step 1.
//
// Google Fonts is disabled via allowRuntimeFetching=false (fonts are
// bundled under assets/fonts/).
//
// Geo data is provided by [FakeLocationService] injected via
// [LocationService.testOverride], bypassing SharedPreferences and the
// country_state_city package entirely.
//
// pumpAndSettle() is deliberately avoided because the AnimatedContainer
// and AnimatedOpacity widgets with continuous animations would time out.

import 'package:mechmate_app/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/shared/services/location_service.dart';

import 'test_utils.dart';

// ===================================================================
// Tests
// ===================================================================

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Create Account flow from Login Screen', () {
    tearDown(() {
      LocationService.clearTestOverride();
    });

    /// Shared app builder used by both tests.
    /// Wraps all routes with a single [MockAuthProvider] via
    /// [MaterialApp.builder] so route-pushed screens can access it.
    Widget buildApp(MockAuthProvider auth) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return ChangeNotifierProvider<AppAuthProvider>.value(
            value: auth,
            child: child!,
          );
        },
        home: const LoginScreen(),
        routes: <String, WidgetBuilder>{
          AppRoutes.registerOwner: (_) => const RegisterOwnerScreen(),
          AppRoutes.ownerMain: (_) => const OwnerMainPlaceholder(),
          AppRoutes.login: (_) => const LoginScreen(),
        },
      );
    }

    testWidgets('completes registration with vehicle details',
        (WidgetTester tester) async {
      await prewarmAndInjectGeoService(tester);
      final auth = MockAuthProvider();
      auth.setSuccess();

      await tester.pumpWidget(buildApp(auth));
      // Let the LoginScreen's initial build + animations settle
      await settleAsync(tester);

      // ===========================================================
      // PHASE 1 — Navigate from Login to Register
      // ===========================================================

      // The "Register" link is at the bottom of a scrollable form.
      // Scroll it into view.
      final registerLink = find.text('Register');
      await tester.ensureVisible(registerLink);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(registerLink);

      // pushReplacementNamed transition — pump frames
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify we are on the Register Owner screen
      expect(find.text('Register as Owner'), findsOneWidget);

      // ===========================================================
      // PHASE 2 — Fill Step 0 (Account Details + Geo)
      // ===========================================================

      await fillAccountFields(tester);

      // -- Select Country: India -----------------------------------------
      await selectGeoItem(tester, itemName: 'India');
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // -- Select State: Maharashtra -------------------------------------
      await selectGeoItem(tester, itemName: 'Maharashtra');
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // -- Select City: Mumbai -------------------------------------------
      await selectGeoItem(tester, itemName: 'Mumbai');
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // -- Continue to Step 1 --------------------------------------------
      final continueBtn = findPrimaryButton('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(continueBtn);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Vehicle Details'), findsOneWidget);

      // ===========================================================
      // PHASE 3 — Fill Vehicle Details and Create Account
      // ===========================================================

      // Vehicle Type "Car" is selected by default; fill the fields.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Vehicle Number (e.g. MH12AB1234)'),
        'MH12AB1234',
      );
      await settleAsync(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Make (e.g. Honda, Maruti)'),
        'Hyundai',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Model (e.g. City, Swift)'),
        'i20',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Year (e.g. 2021)'),
        '2022',
      );
      await settleAsync(tester);

      // -- Tap Create Account --------------------------------------------
      final createBtn = findPrimaryButton('Create Account');
      await tester.ensureVisible(createBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(createBtn);

      // Let the async registerOwner() complete and route transition render
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
      await pumpForRoute(tester);

      // ===========================================================
      // ASSERTIONS
      // ===========================================================

      // registerOwner was called once
      expect(auth.registerCallCount, equals(1));

      // Geo data propagated correctly through the cascade
      expect(auth.userModel!.country, equals('India'));
      expect(auth.userModel!.countryCode, equals('IN'));
      expect(auth.userModel!.state, equals('Maharashtra'));
      expect(auth.userModel!.city, equals('Mumbai'));

      // Should have navigated to Owner Main Dashboard
      expect(find.text('Owner Main Dashboard'), findsOneWidget);

      // Sign-in should NOT have been called (we only registered)
      expect(auth.signInCallCount, equals(0));
    });

    testWidgets('completes registration without vehicle details (skip)',
        (WidgetTester tester) async {
      await prewarmAndInjectGeoService(tester);
      final auth = MockAuthProvider();
      auth.setSuccess();

      await tester.pumpWidget(buildApp(auth));
      await settleAsync(tester);

      // ===========================================================
      // PHASE 1 — Navigate from Login to Register
      // ===========================================================
      final registerLink = find.text('Register');
      await tester.ensureVisible(registerLink);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(registerLink);

      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Register as Owner'), findsOneWidget);

      // ===========================================================
      // PHASE 2 — Fill Step 0 (Account Details + Geo)
      // ===========================================================
      await fillAccountFields(tester);

      await selectGeoItem(tester, itemName: 'India');
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await selectGeoItem(tester, itemName: 'Maharashtra');
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await selectGeoItem(tester, itemName: 'Mumbai');
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // -- Continue to Step 1 --------------------------------------------
      final continueBtn = findPrimaryButton('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(continueBtn);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Vehicle Details'), findsOneWidget);

      // ===========================================================
      // PHASE 3 — Skip vehicle details, tap Create Account
      // ===========================================================
      final createBtn = findPrimaryButton('Create Account');
      await tester.ensureVisible(createBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(createBtn);

      // Let the async registerOwner() complete and route transition render
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
      await pumpForRoute(tester);

      // ===========================================================
      // ASSERTIONS
      // ===========================================================

      expect(auth.registerCallCount, equals(1));
      expect(auth.userModel!.country, equals('India'));
      expect(auth.userModel!.city, equals('Mumbai'));
      expect(find.text('Owner Main Dashboard'), findsOneWidget);
      expect(auth.signInCallCount, equals(0));
    });

    testWidgets('shows error when registration fails',
        (WidgetTester tester) async {
      await prewarmAndInjectGeoService(tester);
      final auth = MockAuthProvider();
      auth.setFailure('This email is already registered.');

      await tester.pumpWidget(buildApp(auth));
      await settleAsync(tester);

      // Navigate to Register
      final registerLink = find.text('Register');
      await tester.ensureVisible(registerLink);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(registerLink);

      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Register as Owner'), findsOneWidget);

      // Fill Step 0
      await fillAccountFields(tester);

      await selectGeoItem(tester, itemName: 'India');
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await selectGeoItem(tester, itemName: 'Maharashtra');
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await selectGeoItem(tester, itemName: 'Mumbai');
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Continue to Step 1
      final continueBtn = findPrimaryButton('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(continueBtn);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Vehicle Details'), findsOneWidget);

      // Tap Create Account (with failure configured)
      final createBtn = findPrimaryButton('Create Account');
      await tester.ensureVisible(createBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(createBtn);

      // Let the async registerOwner() fail and error SnackBar render
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Register was called once
      expect(auth.registerCallCount, equals(1));

      // Should STAY on the registration screen (did not navigate away)
      expect(find.text('Register as Owner'), findsOneWidget);
      expect(find.text('Vehicle Details'), findsOneWidget);

      // Should show the error message in a SnackBar
      expect(find.text('This email is already registered.'), findsOneWidget);

      // Should NOT have navigated to Owner Main
      expect(find.text('Owner Main Dashboard'), findsNothing);
    });
  });
}
