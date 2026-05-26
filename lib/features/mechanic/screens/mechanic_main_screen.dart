import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'mechanic_dashboard_screen.dart';
import 'manage_bookings_screen.dart';
import 'job_cards_screen.dart';
import 'workshop_profile_screen.dart';
import 'mechanic_profile_screen.dart';

class MechanicMainScreen extends StatefulWidget {
  const MechanicMainScreen({super.key});

  @override
  State<MechanicMainScreen> createState() => _MechanicMainScreenState();
}

class _MechanicMainScreenState extends State<MechanicMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MechanicDashboardScreen(),
    ManageBookingsScreen(),
    JobCardsScreen(),
    WorkshopProfileScreen(),
    MechanicProfileScreen(),
  ];

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
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline_rounded),
              activeIcon: Icon(Icons.work_rounded),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store_rounded),
              label: 'Workshop',
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
