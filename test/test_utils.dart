// Shared test utilities for MechMate widget tests.
//
// Reusable across test files:
//   - OwnerMainPlaceholder  — placeholder screen for owner main route
//   - wrapApp               — wrap a widget in a MaterialApp+provider
//   - wrapRoutePush         — wrap a named route with route arguments
//   - settleAsync           — let async operations settle
//   - pumpForRoute          — pump frames for route transitions
//   - findPrimaryButton     — locate PrimaryButton by label
//   - findAnyDropdown       — match any DropdownButtonFormField
//   - selectGeoItem         — interact with a geo cascading dropdown
//   - fillAccountFields     — fill Step 0 account fields
//   - fillLoginFields       — fill login form fields
//   - fillAndSignIn         — fill login fields and tap Sign In
//   - fillStep0AndTapContinue — fill account fields and tap Continue
//
// Mock/fake classes (FakeLocationService, MockAuthProvider,
// FakeVehicleApiService) live in test/mocks.dart and are re-exported here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/features/auth/providers/auth_provider.dart';
import 'package:mechmate_app/shared/widgets/widgets.dart';

import 'mocks.dart';

export 'mocks.dart';

// ===================================================================
// Placeholder screens
// ===================================================================

/// Minimal owner main dashboard placeholder used during route-navigation
/// assertions.
class OwnerMainPlaceholder extends StatelessWidget {
  const OwnerMainPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Owner Main Dashboard'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context, AppRoutes.login,
                arguments: {'role': UserRole.owner},
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// App wrappers
// ===================================================================

/// Build a MaterialApp wrapping [home] with a [MockAuthProvider].
///
/// Named [routes] can be provided for navigation assertions.  Uses
/// [ChangeNotifierProvider.create] so each test gets a fresh isolated
/// provider instance.
Widget wrapApp(Widget home, {Map<String, WidgetBuilder>? routes}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    routes: routes ?? <String, WidgetBuilder>{},
    home: ChangeNotifierProvider<AppAuthProvider>(
      create: (_) => MockAuthProvider(),
      child: home,
    ),
  );
}

/// Wrapper alias that accepts a pre-built [child] (same as [wrapApp] without
/// named routes).  Useful for tests that build the child/widget inline.
Widget wrapWithProviders(Widget child) {
  return wrapApp(child);
}

/// Build an app that pushes [screen] as a named route with [args].
///
/// Uses [onGenerateRoute] so route arguments are passed correctly to the
/// pushed screen via [RouteSettings.arguments].
Widget wrapRoutePush(
  String routeName,
  Widget screen, {
  Map<String, WidgetBuilder>? additionalRoutes,
  required Map<String, dynamic> args,
}) {
  final extraRoutes = additionalRoutes ?? <String, WidgetBuilder>{};
  return MaterialApp(
    theme: AppTheme.lightTheme,
    initialRoute: routeName,
    onGenerateRoute: (settings) {
      if (settings.name == routeName) {
        return MaterialPageRoute(
          builder: (_) => screen,
          settings: RouteSettings(
            name: settings.name,
            arguments: args,
          ),
        );
      }
      final builder = extraRoutes[settings.name];
      if (builder != null) {
        return MaterialPageRoute(builder: builder, settings: settings);
      }
      return MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Not Found')),
      );
    },
    builder: (context, child) => ChangeNotifierProvider<AppAuthProvider>(
      create: (_) => MockAuthProvider(),
      child: child!,
    ),
  );
}

// ===================================================================
// Async helpers
// ===================================================================

/// Let async operations (SharedPreferences, timers, etc.) settle, then
/// pump frames to render the resulting state.
Future<void> settleAsync(WidgetTester tester) async {
  await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Pump enough frames for a [MaterialPageRoute] transition to complete.
Future<void> pumpForRoute(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

// ===================================================================
// Finder helpers
// ===================================================================

/// Locate a [PrimaryButton] with the given [label].
Finder findPrimaryButton(String label) {
  return find.byWidgetPredicate(
    (w) => w is PrimaryButton && w.label == label,
  );
}

/// Match any [DropdownButtonFormField] regardless of its generic type
/// parameter.  Dart's covariant generics mean `is DropdownButtonFormField`
/// works for any type, unlike [find.byType] which reifies the full generic
/// signature.
Finder findAnyDropdown() {
  return find.byWidgetPredicate((w) => w is DropdownButtonFormField);
}

/// Interact with a geo cascading dropdown: open it and select an item.
///
/// Uses the **last** (most recently enabled) dropdown in the cascade so that
/// Country -> State -> City selections work correctly.
Future<void> selectGeoItem(
  WidgetTester tester, {
  required String itemName,
}) async {
  // Wait for a dropdown to appear (max ~4 seconds).
  int attempts = 0;
  while (findAnyDropdown().evaluate().isEmpty && attempts < 40) {
    await tester.pump(const Duration(milliseconds: 100));
    attempts++;
  }

  if (findAnyDropdown().evaluate().isEmpty) {
    final labels = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .toList();
    debugDumpApp();
    throw StateError(
      'Cannot find DropdownButtonFormField after $attempts attempts (item=$itemName).\n'
      'Text labels found: $labels'
    );
  }

  // Use the last (most recently enabled) dropdown in the cascade.
  final dd = findAnyDropdown().last;
  await tester.ensureVisible(dd);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(dd);
  await tester.pump(const Duration(milliseconds: 300));

  // Tap the item in the overlay (.last because overlays render after main tree).
  await tester.tap(find.text(itemName).last);
  await tester.pump(const Duration(milliseconds: 200));
}

// ===================================================================
// Form-filling helpers
// ===================================================================

/// Fill all Step 0 - Account Details fields on the RegisterOwnerScreen.
Future<void> fillAccountFields(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Full Name'), 'Test User',
  );
  await settleAsync(tester);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email Address'), 'test@mechmate.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Phone Number'), '9876543210',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'), 'Test@123',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Confirm Password'), 'Test@123',
  );
  await settleAsync(tester);
}

/// Fill the login form fields on the LoginScreen.
Future<void> fillLoginFields(WidgetTester tester, {
  String email = 'test@mechmate.com',
  String password = 'Test@123',
}) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email Address'), email,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'), password,
  );
  await settleAsync(tester);
}

/// Fill email + password fields and tap the Sign In button.
///
/// After tapping, pumps aggressively so the async signIn completes and the
/// route transition renders.
Future<void> fillAndSignIn(WidgetTester tester,
    {String email = 'test@mechmate.com', String password = 'Test@123'}) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email Address'),
    email,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    password,
  );
  await settleAsync(tester);

  final signInBtn = findPrimaryButton('Sign In');
  await tester.ensureVisible(signInBtn);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(signInBtn);

  // Run async (the mock's 10ms delay + route transition animations)
  await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
  // Pump enough frames for the MaterialPageRoute transition to complete
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Fill Step 0's text fields and ensure the Continue button is visible.
///
/// The Continue button is at the bottom of a scrollable form and may be
/// off-screen in the default 800x600 viewport.  Scrolls it into view before
/// tapping.
Future<void> fillStep0AndTapContinue(WidgetTester tester) async {
  await fillAccountFields(tester);

  final continueBtn = findPrimaryButton('Continue');
  await tester.ensureVisible(continueBtn);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(continueBtn);
  await settleAsync(tester);
}
