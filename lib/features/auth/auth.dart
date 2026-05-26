/// Top-level barrel for the auth feature.
///
/// Re-exports all public auth modules so consumers can import everything
/// auth-related with a single import:
///
/// ```dart
/// import 'package:mechmate_app/features/auth/auth.dart';
/// ```
library;

export 'models/user_model.dart';
export 'providers/auth_provider.dart';
export 'screens/login_screen.dart';
export 'screens/otp_verification_screen.dart';
export 'screens/register_mechanic_screen.dart';
export 'screens/register_owner_screen.dart';
export 'screens/role_selection_screen.dart';
export 'screens/splash_screen.dart';
