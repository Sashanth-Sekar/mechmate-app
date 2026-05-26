import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'owner_home_screen.dart';
import 'search_workshops_screen.dart';
import 'my_bookings_screen.dart';
import 'my_vehicles_screen.dart';
import 'owner_profile_screen.dart';

class OwnerMainScreen extends StatefulWidget {
  const OwnerMainScreen({super.key});

  @override
  State<OwnerMainScreen> createState() => _OwnerMainScreenState();
}

class _OwnerMainScreenState extends State<OwnerMainScreen> {
  int _currentIndex = 0;

  /// Screens in the IndexedStack: Home, Bookings, Vehicles, Profile
  /// Search is NOT in the stack — it's pushed as a route instead.
  static const List<Widget> _screens = [
    OwnerHomeScreen(),
    MyBookingsScreen(),
    MyVehiclesScreen(),
    OwnerProfileScreen(),
  ];

  /// Bottom nav items: Home(0), Search(push), Bookings(2), Vehicles(3), Profile(4)
  int _displayIndex() {
    return _currentIndex == 0 ? 0 : _currentIndex + 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBg : const Color(0xFFF4F5F0),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          currentIndex: _displayIndex(),
          onTap: (i) {
            // Index 1 = Search — push as a full route
            if (i == 1) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SearchWorkshopsScreen(),
                ),
              );
              return;
            }
            // Map bottom nav index to _screens index:
            //   0 -> 0 (Home)
            //   2 -> 1 (Bookings)
            //   3 -> 2 (Vehicles)
            //   4 -> 3 (Profile)
            setState(() {
              _currentIndex = i > 1 ? i - 1 : i;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car_rounded),
              label: 'Vehicles',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
