class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String roleSelect = '/role-select';
  static const String login = '/login';
  static const String registerOwner = '/register/owner';
  static const String registerMechanic = '/register/mechanic';
  static const String ownerMain = '/owner';
  static const String mechanicMain = '/mechanic';
  static const String otpVerification = '/otp-verification';
}

enum UserRole { owner, mechanic }

class ServiceTypes {
  ServiceTypes._();
  static const List<String> all = [
    'Oil Change',
    'Tyre Service',
    'Brake Service',
    'Engine Repair',
    'AC Service',
    'Body Work',
    'Electrical',
    'Battery',
    'Wheel Alignment',
    'Suspension',
    'Exhaust',
    'Full Service',
  ];
}

class BookingStatus {
  BookingStatus._();
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String active = 'active';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class AppConfig {
  AppConfig._();
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';
}

/// Feature flags for disabling incomplete future features.
class FeatureFlags {
  FeatureFlags._();

  /// Job Cards — Phase 2 (mechanic inventory / job tracking).
  /// When false, the mechanic tab and any entry points are hidden.
  static const bool jobCardsEnabled = false;

  /// AI Diagnostics — Phase 3.
  static const bool aiDiagnosticsEnabled = false;

  /// 3D Vehicle Visualization — Phase 3.
  static const bool vehicle3DEnabled = false;

  /// Payments module — Phase 1, enable once integrated.
  static const bool paymentsEnabled = false;

  /// Live GPS tracking — Phase 2.
  static const bool liveTrackingEnabled = false;
}

class VehicleMakes {
  VehicleMakes._();
  static const List<String> cars = [
    'Maruti Suzuki',
    'Hyundai',
    'Tata',
    'Mahindra',
    'Honda',
    'Toyota',
    'Kia',
    'Renault',
    'Volkswagen',
    'Ford',
    'Other',
  ];
  static const List<String> bikes = [
    'Hero',
    'Honda',
    'Bajaj',
    'TVS',
    'Royal Enfield',
    'Yamaha',
    'Suzuki',
    'KTM',
    'Jawa',
    'Other',
  ];
}
