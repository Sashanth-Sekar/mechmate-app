// Widget test for the Owner Registration flow.
//
// Covers:
//   1. UI rendering: all form fields, geo-selector, buttons
//   2. Form validation: required fields, email format, password match
//   3. Step navigation: Account Details (step 0) -> Vehicle Details (step 1)
//   4. Geo-selector: country, state, city section labels
//   5. Back navigation from Step 1 to Step 0
//
// Google Fonts is disabled via allowRuntimeFetching=false because the
// font HTTP requests fail in the test environment.  Text falls back to
// the system default.
//
// Geo data is provided by [FakeLocationService] injected via
// [LocationService.testOverride], bypassing SharedPreferences and the
// country_state_city package entirely.
//
// pumpAndSettle() is deliberately avoided because the AnimatedContainer
// and AnimatedOpacity widgets with continuous animations would time out.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mechmate_app/features/auth/screens/register_owner_screen.dart';
import 'package:mechmate_app/shared/services/location_service.dart';
import 'package:mechmate_app/shared/widgets/widgets.dart';

import 'test_utils.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Google Fonts are now bundled under assets/fonts/ in pubspec.yaml,
  // so allowRuntimeFetching = false works without network errors.
  GoogleFonts.config.allowRuntimeFetching = false;

  tearDown(() {
    LocationService.clearTestOverride();
  });

  group('RegisterOwnerScreen - Step 0 (Account Details)', () {
    testWidgets('renders all account fields, geo-selector, and Continue button',
        (WidgetTester tester) async {
      await prewarmAndInjectGeoService(tester);
      await tester.pumpWidget(
        wrapWithProviders(const RegisterOwnerScreen()),
      );
      // Let the FakeLocationService async _load() chain complete.
      await settleAsync(tester);

      expect(find.text('Account Details'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Email Address'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Phone Number'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Confirm Password'), findsOneWidget);
      expect(find.byType(GeoSelector), findsOneWidget);
      expect(findPrimaryButton('Continue'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty required fields',
        (WidgetTester tester) async {
      await prewarmAndInjectGeoService(tester);
      await tester.pumpWidget(
        wrapWithProviders(const RegisterOwnerScreen()),
      );
      await settleAsync(tester);

      final btn = findPrimaryButton('Continue');
      await tester.ensureVisible(btn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(btn);
      await settleAsync(tester);

      // The validators in register_owner_screen.dart:
      //   Name   -> AppValidators.required(v, field: 'Name')   -> 'Name is required'
      //   Email  -> AppValidators.email                        -> 'Email is required'
      //   Phone  -> AppValidators.phone                        -> 'Phone number is required'
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
    });

    testWidgets('advances to Step 1 with valid account details',
        (WidgetTester tester) async {
      await prewarmAndInjectGeoService(tester);
      await tester.pumpWidget(
        wrapWithProviders(const RegisterOwnerScreen()),
      );
      await settleAsync(tester);

      await fillStep0AndTapContinue(tester);

      // Should now show Step 1 -- Vehicle Details
      expect(find.text('Vehicle Details'), findsOneWidget);
      expect(
        find.text('(Optional \u2013 you can add this later)'),
        findsOneWidget,
      );
    });

    testWidgets('shows password mismatch error and stays on Step 0',
        (WidgetTester tester) async {
      await prewarmAndInjectGeoService(tester);
      await tester.pumpWidget(
        wrapWithProviders(const RegisterOwnerScreen()),
      );
      await settleAsync(tester);

      // Fill fields with mismatched passwords
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'test@mechmate.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number'),
        '9876543210',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Test@123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'DifferentPwd1!',
      );
      await settleAsync(tester);

      final continueBtn = findPrimaryButton('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(continueBtn);
      await settleAsync(tester);

      // Validation error for confirm mismatch
      expect(find.text('Passwords do not match'), findsOneWidget);
      // Should still be on Step 0
      expect(find.text('Account Details'), findsOneWidget);
    });
  });

  group('RegisterOwnerScreen - Step 1 (Vehicle Details)', () {
    testWidgets('renders vehicle fields and Create Account button',
        (WidgetTester tester) async {
      await prewarmAndInjectGeoService(tester);
      await tester.pumpWidget(
        wrapWithProviders(const RegisterOwnerScreen()),
      );
      await settleAsync(tester);
      await fillStep0AndTapContinue(tester);

      // Step 1 fields
      expect(find.text('Vehicle Details'), findsOneWidget);
      expect(find.text('Car'), findsOneWidget);
      expect(find.text('Bike'), findsOneWidget);
      expect(
        find.widgetWithText(
            TextFormField, 'Vehicle Number (e.g. MH12AB1234)'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Make (e.g. Honda, Maruti)'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Model (e.g. City, Swift)'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Year (e.g. 2021)'),
        findsOneWidget,
      );
      expect(findPrimaryButton('Create Account'), findsOneWidget);
    });
  });

  group('RegisterOwnerScreen - Geo Selector', () {
    testWidgets('renders Country, State / Province, and City section labels',
        (WidgetTester tester) async {
      await prewarmAndInjectGeoService(tester);
      await tester.pumpWidget(
        wrapWithProviders(const RegisterOwnerScreen()),
      );
      await settleAsync(tester);

      // The _GlassDividerLabel in GeoSelector renders "Country",
      // "State / Province", and "City" as section headings.
      //
      // "State / Province" appears twice because:
      //   1. GeoSelector's _GlassDividerLabel(label: 'State / Province')
      //   2. StateDropdown's GlassDropdown has label: 'State / Province'
      //      which is rendered by its _LabelRow widget.
      expect(find.text('Country'), findsOneWidget);
      expect(find.text('State / Province'), findsAtLeast(1));
      expect(find.text('City'), findsAtLeast(1));
    });
  });

  group('RegisterOwnerScreen - Navigation', () {
    testWidgets('back button on Step 1 returns to Step 0',
        (WidgetTester tester) async {
      await prewarmAndInjectGeoService(tester);
      await tester.pumpWidget(
        wrapWithProviders(const RegisterOwnerScreen()),
      );
      await settleAsync(tester);
      await fillStep0AndTapContinue(tester);

      // Verify we're on Step 1
      expect(find.text('Vehicle Details'), findsOneWidget);

      // Tap the back arrow in the AppBar
      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await settleAsync(tester);

      // Should now be back on Step 0
      expect(find.text('Account Details'), findsOneWidget);
    });
  });
}
