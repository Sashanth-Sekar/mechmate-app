// Widget tests for SearchWorkshopsScreen.
//
// Uses FakeMechMapController to avoid platform-channel dependencies (Google
// Maps, Geolocator) and a mapViewBuilder to replace the PremiumMapView with a
// plain Container.

import 'package:mechmate_app/features/owner/owner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


import 'mocks.dart';

// ===================================================================
// Helpers
// ===================================================================

/// A simple map view replacement that avoids Google Maps platform channels.
Widget _mapPlaceholder(MechMapController controller) {
  return Container(
    color: const Color(0xFF10141B),
  );
}

/// Wrap [child] in a MaterialApp so navigation APIs work.
Widget _wrapApp(Widget child) {
  return MaterialApp(home: child);
}

/// Convenience: build a [SearchWorkshopsScreen] wired to [fakeController].
Widget _buildScreen(FakeMechMapController fakeController) {
  return _wrapApp(
    SearchWorkshopsScreen(
      controller: fakeController,
      mapViewBuilder: _mapPlaceholder,
    ),
  );
}

/// Sample shops for list-display tests.
final _sampleShops = [
  ShopModel(
    id: 'ws-1',
    name: 'Speed Garage',
    latitude: 18.5204,
    longitude: 73.8567,
    rating: 4.5,
    distance: 1.2,
    isOpen: true,
    services: ['Oil Change', 'Tire Rotation'],
  ),
  ShopModel(
    id: 'ws-2',
    name: 'AutoCare Hub',
    latitude: 18.5300,
    longitude: 73.8600,
    rating: 3.8,
    distance: 2.5,
    isOpen: false,
    services: ['AC Service', 'Brake Repair'],
  ),
];

// ===================================================================
// Tests
// ===================================================================

void main() {
  group('SearchWorkshopsScreen', () {
    testWidgets('renders loading state initially', (tester) async {
      final controller = FakeMechMapController();
      // initialize() is called in initState — it sets isLoading=true but
      // does NOT auto-resolve.  The first frame shows the loading overlay.
      await tester.pumpWidget(_buildScreen(controller));
      await tester.pump();

      // Loading overlay should be visible
      expect(find.text('Finding your precise location...'), findsOneWidget);

      // Resolve loading so the test ends cleanly (no pending work).
      controller.resolveLoading();
      await tester.pump();
    });

    testWidgets('transitions from loading to empty state', (tester) async {
      final controller = FakeMechMapController();

      await tester.pumpWidget(_buildScreen(controller));
      await tester.pump();

      // Still loading
      expect(find.text('Finding your precise location...'), findsOneWidget);

      // Resolve loading
      controller.resolveLoading();
      await tester.pump();

      // Now shows empty state
      expect(find.text('No workshops found nearby'), findsOneWidget);
    });

    testWidgets('shows empty state when no workshops found', (tester) async {
      final controller = FakeMechMapController();

      await tester.pumpWidget(_buildScreen(controller));
      controller.resolveLoading();
      await tester.pump();

      // Empty state text
      expect(find.text('No workshops found nearby'), findsOneWidget);
      // Search bar should be visible
      expect(find.byType(MapGlassSearchBar), findsOneWidget);
      // Current location button should be visible
      expect(find.byType(CurrentLocationButton), findsOneWidget);
    });

    testWidgets('displays workshop list', (tester) async {
      final controller = FakeMechMapController();
      controller.shops = _sampleShops;

      await tester.pumpWidget(_buildScreen(controller));
      controller.resolveLoading();
      await tester.pump();

      // Each shop name should be visible
      expect(find.text('Speed Garage'), findsOneWidget);
      expect(find.text('AutoCare Hub'), findsOneWidget);
      // WorkshopListItem widgets should be rendered
      expect(find.byType(WorkshopListItem), findsNWidgets(2));
    });

    testWidgets('search bar accepts input and calls refreshNearbyShops',
        (tester) async {
      final controller = FakeMechMapController();

      await tester.pumpWidget(_buildScreen(controller));
      controller.resolveLoading();
      await tester.pump();

      // Find the search TextField inside MapGlassSearchBar
      final searchField = find.widgetWithText(
        TextField,
        'Search service or workshop',
      );
      expect(searchField, findsOneWidget);

      // Enter search text
      await tester.enterText(searchField, 'Engine');
      // Pump past the 280ms debounce
      await tester.pump(const Duration(milliseconds: 350));

      // Verify the fake controller received the query
      expect(controller.lastQuery, 'Engine');
    });

    testWidgets('back button pops the navigator', (tester) async {
      final controller = FakeMechMapController();

      // Wrap in a route so we can test that pop removes the screen.
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchWorkshopsScreen(
                      controller: controller,
                      mapViewBuilder: _mapPlaceholder,
                    ),
                  ),
                );
              },
              child: const Text('Open Search'),
            ),
          ),
        ),
      );

      // Navigate to the search screen
      await tester.tap(find.text('Open Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Resolve loading on the pushed controller
      controller.resolveLoading();
      await tester.pump();

      // Now we should be on the search screen
      expect(find.byType(SearchWorkshopsScreen), findsOneWidget);

      // Tap the back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // The SearchWorkshopsScreen should be gone
      expect(find.byType(SearchWorkshopsScreen), findsNothing);
    });

    testWidgets('custom controller is used when provided', (tester) async {
      final controller = FakeMechMapController();
      expect(controller.initializeCalled, isFalse);

      await tester.pumpWidget(_buildScreen(controller));

      expect(controller.initializeCalled, isTrue);

      // Resolve loading so the test ends cleanly.
      controller.resolveLoading();
      await tester.pump();
    });

    testWidgets('shows fetching indicator while fetching shops',
        (tester) async {
      final controller = FakeMechMapController();

      await tester.pumpWidget(_buildScreen(controller));
      controller.resolveLoading();
      await tester.pump();

      // Now set fetching state and pump
      controller.isFetchingShops = true;
      controller.notifyListeners();
      await tester.pump();

      // The fetching indicator is a CircularProgressIndicator inside the map
      // area
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Clear fetching so the test ends cleanly.
      controller.isFetchingShops = false;
      controller.notifyListeners();
      await tester.pump();
    });

    testWidgets('selecting a shop from the list calls selectShop',
        (tester) async {
      final controller = FakeMechMapController();
      controller.shops = _sampleShops;

      await tester.pumpWidget(_buildScreen(controller));
      controller.resolveLoading();
      await tester.pump();

      // Ensure the list item is visible and tap it
      final item = find.text('Speed Garage');
      await tester.ensureVisible(item);
      await tester.pump();
      await tester.tap(item);
      await tester.pump();

      // Verify the shop was selected
      expect(controller.selectedShop?.id, 'ws-1');
    });
  });
}
