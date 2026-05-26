// Mock AppAuthProvider for widget tests.
//
// Configurable mock suitable for both registration and login widget tests.
// Tracks call counts and allows tests to drive success / failure / loading
// state without real Firebase calls.

import 'package:mechmate_app/features/auth/auth.dart';
import 'package:mechmate_app/core/constants/constants.dart';
import 'package:mechmate_app/features/owner/models/vehicle_model.dart';
import 'package:mechmate_app/shared/shared.dart';

// ===================================================================
// Mock AppAuthProvider
// ===================================================================

/// Configurable mock of [AppAuthProvider] suitable for both registration and
/// login widget tests.  Tracks call counts and allows tests to drive
/// success / failure / loading state without real Firebase calls.
class MockAuthProvider extends AppAuthProvider {
  MockAuthProvider() : super(AuthService());

  // ---- Seam state --------------------------------------------------

  bool _shouldSucceed = true;
  String? _mockError;
  UserModel? _mockUser;
  bool _mockLoading = false;
  String? _mockVerificationId;
  int _signInCallCount = 0;
  int _registerCallCount = 0;

  // ---- Queries for test assertions ---------------------------------

  /// Number of times [signIn] was called.
  int get signInCallCount => _signInCallCount;

  /// Number of times [registerOwner] or [registerMechanic] was called.
  int get registerCallCount => _registerCallCount;

  @override
  UserModel? get userModel => _mockUser;

  @override
  String? get errorMessage => _mockError;

  @override
  bool get isLoading => _mockLoading;

  @override
  String? get verificationId => _mockVerificationId;

  // ---- Configuration helpers ---------------------------------------

  /// Configure the mock to return success for the next operation and set a
  /// default user model with the given [role].
  void setSuccess({UserRole role = UserRole.owner}) {
    _shouldSucceed = true;
    _mockUser = UserModel(
      uid: 'test-uid',
      name: 'Test User',
      email: 'test@mechmate.com',
      phone: '9876543210',
      role: role,
      createdAt: DateTime.now(),
      country: 'India',
      countryCode: 'IN',
      state: 'Maharashtra',
      stateCode: 'MH',
      city: 'Mumbai',
    );
    _mockError = null;
    notifyListeners();
  }

  /// Configure the mock to fail with the given error [message].
  void setFailure(String message) {
    _shouldSucceed = false;
    _mockUser = null;
    _mockError = message;
    _mockLoading = false;
    notifyListeners();
  }

  // ---- Overridden methods ------------------------------------------

  @override
  Future<bool> signIn(String email, String password, [UserRole? role]) async {
    _signInCallCount++;
    _mockLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    _mockLoading = false;
    notifyListeners();
    return _shouldSucceed;
  }

  @override
  Future<bool> sendOTP(String phone) async {
    _mockVerificationId = 'mock-verification-id';
    _mockLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    _mockLoading = false;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> verifyOTP(String otp) async {
    _mockLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    _mockLoading = false;
    if (_shouldSucceed && _mockVerificationId != null) {
      return true;
    }
    _mockError = _mockError ?? 'Invalid OTP.';
    return false;
  }

  @override
  Future<bool> registerOwner({
    required String name,
    required String email,
    required String password,
    required String phone,
    VehicleModel? initialVehicle,
    required GeoSelection geo,
  }) async {
    _registerCallCount++;
    _mockLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    _mockLoading = false;
    if (_shouldSucceed) {
      _mockUser ??= UserModel(
        uid: 'registered-uid',
        name: name,
        email: email,
        phone: phone,
        role: UserRole.owner,
        createdAt: DateTime.now(),
        country: geo.country,
        countryCode: geo.countryCode,
        state: geo.state,
        stateCode: geo.stateCode,
        city: geo.city,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  Future<bool> registerMechanic({
    required String name,
    required String email,
    required String password,
    required String phone,
    required GeoSelection geo,
    required String workshopName,
    required String workshopAddress,
    required String workshopPincode,
    required String openTime,
    required String closeTime,
    required List<String> vehicleTypes,
    required List<String> services,
    required GeoSelection workshopGeo,
  }) async {
    _registerCallCount++;
    _mockLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    _mockLoading = false;
    if (_shouldSucceed) {
      _mockUser ??= UserModel(
        uid: 'registered-uid',
        name: name,
        email: email,
        phone: phone,
        role: UserRole.mechanic,
        createdAt: DateTime.now(),
        country: geo.country,
        countryCode: geo.countryCode,
        state: geo.state,
        stateCode: geo.stateCode,
        city: geo.city,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Safe override so tapping "Send" in the forgot-password dialog
  /// doesn't crash with a real Firebase Auth call.
  @override
  Future<bool> resetPassword(String email) async {
    _mockLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    _mockLoading = false;
    _mockError = _shouldSucceed ? null : 'Failed to send reset link';
    notifyListeners();
    return _shouldSucceed;
  }
}
