// Widget test for the chained register → login flow.
//
// Tests that a user can register a new account (with geo-selector), then
// sign in with the same credentials. Both screens use the *same* mock
// provider instance so state (userModel, errorMessage) is shared across
// phases.
//
// Google Fonts is disabled via allowRuntimeFetching=false (fonts are
// bundled under assets/fonts/).
//
// The geo selector's CountryDropdown / StateDropdown / CityDropdown all
// create LocationService() internally. We inject a FakeLocationService
// via LocationService.testOverride that returns hardcoded geo data
// (India → Maharashtra → Mumbai) without any SharedPreferences or
// network dependency.

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

  group('Chained register → login flow', () {
    tearDown(() {
      LocationService.clearTestOverride();
    });

    testWidgets('registers a user, then signs in with same credentials',
        (WidgetTester tester) async {
      // ---------------------------------------------------------------
      // Phase 0: Pre-warm SharedPreferences and inject FakeLocationService.
      // ---------------------------------------------------------------
      await prewarmAndInjectGeoService(tester);

      final auth = MockAuthProvider();

      Widget buildApp() => MaterialApp(
        theme: AppTheme.lightTheme,
        // Wrap ALL routes with the shared provider via MaterialApp.builder.
        builder: (context, child) {
          return ChangeNotifierProvider<AppAuthProvider>.value(
            value: auth,
            child: child!,
          );
        },
        home: const RegisterOwnerScreen(),
        routes: <String, WidgetBuilder>{
          AppRoutes.ownerMain: (_) => const OwnerMainPlaceholder(),
          AppRoutes.login: (_) => const LoginScreen(),
        },
      );

      await tester.pumpWidget(buildApp());

      // Let the async _load() chain complete. The FakeLocationService
      // returns results immediately via microtask processing.
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // =================================================================
      // PHASE 1 — REGISTRATION
      // =================================================================

      // -- Step 0: Fill account fields ----------------------------------
      await fillAccountFields(tester);

      // -- Select Country: India -----------------------------------------
      await selectGeoItem(tester, itemName: 'India');

      // -- Let StateDropdown load (FakeLocationService returns instantly) --
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // -- Select State: Maharashtra -------------------------------------
      await selectGeoItem(tester, itemName: 'Maharashtra');

      // -- Let CityDropdown load -----------------------------------------
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // -- Select City: Mumbai -------------------------------------------
      await selectGeoItem(tester, itemName: 'Mumbai');

      // -- Continue to Step 1 (Vehicle Details) --------------------------
      final continueBtn = findPrimaryButton('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(continueBtn);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify we are on Step 1
      expect(find.text('Vehicle Details'), findsOneWidget);

      // -- Skip vehicle details, tap "Create Account" --------------------
      final createBtn = findPrimaryButton('Create Account');
      await tester.ensureVisible(createBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(createBtn);

      // Let the async registerOwner() complete and route transition render
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
      await pumpForRoute(tester);

      // Verify registration completed: registerOwner was called once
      expect(auth.registerCallCount, equals(1));
      // Verify geo data was captured correctly through the cascade
      expect(auth.userModel!.country, equals('India'));
      expect(auth.userModel!.countryCode, equals('IN'));
      expect(auth.userModel!.state, equals('Maharashtra'));
      expect(auth.userModel!.city, equals('Mumbai'));
      // Should have navigated to Owner Main Dashboard
      expect(find.text('Owner Main Dashboard'), findsOneWidget);

      // =================================================================
      // PHASE 2 — LOGIN with same credentials
      // =================================================================
      final goToLoginBtn = find.text('Go to Login');
      await tester.ensureVisible(goToLoginBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(goToLoginBtn);

      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
      await pumpForRoute(tester);

      // Verify the login screen rendered
      expect(find.text('Welcome Back'), findsOneWidget);

      // -- Fill login fields ---------------------------------------------
      await fillLoginFields(tester);

      // -- Tap Sign In ---------------------------------------------------
      final signInBtn = findPrimaryButton('Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(signInBtn);

      // Let the async signIn() complete and route transition render
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
      await pumpForRoute(tester);

      // Verify signIn was called
      expect(auth.signInCallCount, equals(1));
      // Should have navigated back to the owner main dashboard
      expect(find.text('Owner Main Dashboard'), findsOneWidget);
    });
  });
}
