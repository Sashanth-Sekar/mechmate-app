/// Top-level barrel for the mechanic feature.
///
/// Re-exports all public mechanic modules so consumers can import everything
/// mechanic-related with a single import:
///
/// ```dart
/// import 'package:mechmate_app/features/mechanic/mechanic.dart';
/// ```
library;

export 'models/job_card_model.dart';
export 'models/workshop_model.dart';
export 'screens/job_cards_screen.dart';
export 'screens/manage_bookings_screen.dart';
export 'screens/mechanic_dashboard_screen.dart';
export 'screens/mechanic_main_screen.dart';
export 'screens/mechanic_profile_screen.dart';
export 'screens/workshop_profile_screen.dart';
