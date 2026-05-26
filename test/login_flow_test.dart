// Widget tests for the Login flow.
//
// Covers:
//   1. LoginScreen — UI rendering, form validation, error handling,
//      successful navigation, password toggle, forgot-password dialog
//   2. OtpVerificationScreen — OTP field, verify button, resend link
//   3. RoleSelectionScreen — role cards, navigation to login / register
//
// Google Fonts is disabled via allowRuntimeFetching=false (fonts are
// bundled under assets/fonts/).
//
// pumpAndSettle() is deliberately avoided — animations (AnimatedOpacity,
// AnimatedScale, SlideTransition, LoadingOverlay spinner) would time out.

import 'package:mechmate_app/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:mechmate_app/core/core.dart';

import 'test_utils.dart';

// ===================================================================
// Tests
// ===================================================================

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // ---------------------------------------------------------------
  // LoginScreen
  // ---------------------------------------------------------------
  group('LoginScreen', () {
    testWidgets('renders all form fields, Sign In button, and links',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapApp(const LoginScreen()));
      await settleAsync(tester);

      // Title & subtitle
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue to MechMate'), findsOneWidget);

      // Form fields
      expect(
          find.widgetWithText(TextFormField, 'Email Address'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

      // Buttons & links
      expect(findPrimaryButton('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);

      // Role badge defaults to Vehicle Owner (no route arg → owner)
      expect(find.text('Vehicle Owner'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapApp(const LoginScreen()));
      await settleAsync(tester);

      final signInBtn = findPrimaryButton('Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(signInBtn);
      await settleAsync(tester);

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapApp(const LoginScreen()));
      await settleAsync(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'not-an-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Test@123',
      );
      await settleAsync(tester);

      final signInBtn = findPrimaryButton('Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(signInBtn);
      await settleAsync(tester);

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('toggles password visibility on icon tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapApp(const LoginScreen()));
      await settleAsync(tester);

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('shows error snackbar and stays on login screen on failed sign in',
        (WidgetTester tester) async {
      final auth = MockAuthProvider()
        ..setFailure('Invalid email or password.');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AppAuthProvider>(
            create: (_) => auth,
            child: const LoginScreen(),
          ),
        ),
      );
      await settleAsync(tester);

      await fillAndSignIn(tester);

      // SnackBar shows the error message
      expect(find.text('Invalid email or password.'), findsOneWidget);

      // User stays on the login screen (no navigation occurred)
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue to MechMate'), findsOneWidget);
      expect(findPrimaryButton('Sign In'), findsOneWidget);

      // signIn was called once
      expect(auth.signInCallCount, equals(1));
    });

    testWidgets('shows network error snackbar for connection failure',
        (WidgetTester tester) async {
      final auth = MockAuthProvider()
        ..setFailure('Network error. Please check your internet connection.');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AppAuthProvider>(
            create: (_) => auth,
            child: const LoginScreen(),
          ),
        ),
      );
      await settleAsync(tester);

      await fillAndSignIn(tester);

      expect(
        find.text('Network error. Please check your internet connection.'),
        findsOneWidget,
      );
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(auth.signInCallCount, equals(1));
    });

    testWidgets('shows generic error snackbar for unknown errors',
        (WidgetTester tester) async {
      final auth = MockAuthProvider()
        ..setFailure('Something went wrong. Please try again.');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AppAuthProvider>(
            create: (_) => auth,
            child: const LoginScreen(),
          ),
        ),
      );
      await settleAsync(tester);

      await fillAndSignIn(tester);

      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(auth.signInCallCount, equals(1));
    });

    testWidgets('calls signIn and navigates to owner main on success',
        (WidgetTester tester) async {
      final auth = MockAuthProvider()
        ..setSuccess(role: UserRole.owner);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AppAuthProvider>(
            create: (_) => auth,
            child: const LoginScreen(),
          ),
          routes: {
            AppRoutes.ownerMain: (_) =>
                const Scaffold(body: Text('Owner Main Dashboard')),
          },
        ),
      );
      await settleAsync(tester);

      await fillAndSignIn(tester);

      // Verify signIn was called on the mock
      expect(auth.signInCallCount, equals(1));
      // Verify the login screen is no longer the active route
      expect(find.text('Welcome Back'), findsNothing);
      // Verify we navigated to the owner main route
      expect(find.text('Owner Main Dashboard'), findsOneWidget);
    });

    testWidgets('calls signIn and navigates to mechanic main on success',
        (WidgetTester tester) async {
      final auth = MockAuthProvider()
        ..setSuccess(role: UserRole.mechanic);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AppAuthProvider>(
            create: (_) => auth,
            child: const LoginScreen(),
          ),
          routes: {
            AppRoutes.mechanicMain: (_) =>
                const Scaffold(body: Text('Mechanic Main Dashboard')),
          },
        ),
      );
      await settleAsync(tester);

      await fillAndSignIn(tester);

      expect(auth.signInCallCount, equals(1));
      expect(find.text('Welcome Back'), findsNothing);
      expect(find.text('Mechanic Main Dashboard'), findsOneWidget);
    });

    testWidgets('shows Workshop Mechanic badge and Register navigates to RegisterMechanicScreen',
        (WidgetTester tester) async {
      // Pre-warm SharedPreferences so the GeoSelector on Step 0 of
      // RegisterMechanicScreen renders without crashing.
      await prewarmAndInjectGeoService(tester);

      await tester.pumpWidget(
        wrapRoutePush(
          AppRoutes.login,
          const LoginScreen(),
          args: {'role': UserRole.mechanic},
          additionalRoutes: {
            AppRoutes.registerMechanic: (_) => const RegisterMechanicScreen(),
          },
        ),
      );
      await settleAsync(tester);

      // Role badge shows Workshop Mechanic (not Vehicle Owner)
      expect(find.text('Workshop Mechanic'), findsOneWidget);
      expect(find.text('Vehicle Owner'), findsNothing);

      // Tap the Register link at the bottom
      final registerLink = find.text('Register');
      await tester.ensureVisible(registerLink);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(registerLink);

      // pushReplacementNamed transition — pump frames
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Should have navigated to RegisterMechanicScreen
      expect(find.text('Register Workshop'), findsOneWidget);
      // Login screen should be gone (pushReplacementNamed)
      expect(find.text('Welcome Back'), findsNothing);
    });

    testWidgets('opens and dismisses forgot password dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapApp(const LoginScreen()));
      await settleAsync(tester);

      // Tap Forgot Password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();
      await settleAsync(tester);

      // Dialog should be visible
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);

      // Dismiss via Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Dialog gone
      expect(find.text('Reset Password'), findsNothing);
    });
  });

  // ---------------------------------------------------------------
  // OtpVerificationScreen
  // ---------------------------------------------------------------
  group('OtpVerificationScreen', () {
    testWidgets('renders OTP field, verify button, and resend link',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapApp(const OtpVerificationScreen()));
      await settleAsync(tester);

      expect(find.text('Verify Your Number'), findsOneWidget);
      expect(find.text('Verify & Register'), findsOneWidget);
      expect(find.text("Didn't receive code? "), findsOneWidget);
      expect(find.text('Resend'), findsOneWidget);

      // The OTP text field (TextField, not AppTextField)
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows error for short OTP', (WidgetTester tester) async {
      await tester.pumpWidget(wrapApp(const OtpVerificationScreen()));
      await settleAsync(tester);

      await tester.enterText(find.byType(TextField), '123');
      await settleAsync(tester);

      final verifyBtn = findPrimaryButton('Verify & Register');
      await tester.ensureVisible(verifyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(verifyBtn);
      await settleAsync(tester);

      expect(
        find.text('Please enter a valid 6-digit OTP.'),
        findsOneWidget,
      );
    });

    testWidgets('shows masked phone number when registration data provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapRoutePush(
          AppRoutes.otpVerification,
          const OtpVerificationScreen(),
          args: {
            'phone': '9876543210',
            'role': UserRole.owner,
            'name': 'Test User',
            'email': 'test@mechmate.com',
            'password': 'Test@123',
          },
        ),
      );
      await settleAsync(tester);

      expect(find.textContaining('******3210'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------
  // RoleSelectionScreen
  // ---------------------------------------------------------------
  group('RoleSelectionScreen', () {
    testWidgets('renders both role cards with Register and Login buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapApp(const RoleSelectionScreen()));
      // The RoleSelectionScreen uses a 700ms AnimationController with
      // SlideTransition + FadeTransition.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 400));
      await settleAsync(tester);

      // Branding uses RichText with TextSpan('MECH') + TextSpan('MATE').
      // RichText children are inline spans, not separate Text widgets,
      // so we verify the RichText widget exists instead.
      expect(find.byType(RichText), findsAtLeast(1));

      // Subtitle (these are Text widgets)
      expect(find.text('Who are you?'), findsOneWidget);
      expect(
        find.text('Choose your role to get started'),
        findsOneWidget,
      );

      // Two role cards
      expect(find.text('Vehicle Owner'), findsOneWidget);
      expect(find.text('Workshop Mechanic'), findsOneWidget);

      // Each card has Register + Login
      expect(find.text('Register'), findsNWidgets(2));
      expect(find.text('Login'), findsNWidgets(2));
    });

    testWidgets('tapping Vehicle Owner Login navigates to login screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AppAuthProvider>(
            create: (_) => MockAuthProvider(),
            child: const RoleSelectionScreen(),
          ),
          routes: {
            AppRoutes.login: (_) =>
                const Scaffold(body: Text('Login Screen Here')),
          },
        ),
      );
      // Pump enough frames for the 700ms animation to complete
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 400));
      await settleAsync(tester);

      // Find and tap the Vehicle Owner Login button
      final loginButtons = find.text('Login');
      await tester.ensureVisible(loginButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(loginButtons.first);

      // Run async + pump for navigation animation
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Should have navigated to login
      expect(find.text('Login Screen Here'), findsOneWidget);
    });
  });
}
