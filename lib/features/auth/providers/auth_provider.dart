import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mechmate_app/core/constants/constants.dart';
import 'package:mechmate_app/features/auth/models/user_model.dart';
import 'package:mechmate_app/shared/shared.dart';
import 'package:mechmate_app/features/mechanic/models/workshop_model.dart';
import 'package:mechmate_app/features/owner/models/vehicle_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppAuthProvider extends ChangeNotifier {
  static const Duration _operationTimeout = Duration(seconds: 20);
  static const Duration _profileStorageTimeout = Duration(seconds: 8);

  final AuthService _authService;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  AppAuthProvider(this._authService) {
    _init();
  }

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _userModel != null;

  Future<void> _init() async {
    _setLoading(true);
    try {
      final current = _authService.currentUser;
      if (current != null) {
        _userModel = await _authService.getUserModel(current.uid);
        if (_userModel == null) {
          await _authService.signOut();
        } else {
          // Initialize the shared API client before signaling readiness
          await _initApiClient(_userModel!.role.name);
        }
      }
    } catch (e) {
      debugPrint('Auth init failed: $e');
      _userModel = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password, [UserRole? role]) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _userModel = await _authService.signIn(email, password, role);
      if (_userModel != null) {
        await _initApiClient(_userModel!.role.name);
      }
      return _userModel != null;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String? _verificationId;

  String? get verificationId => _verificationId;

  Future<bool> sendOTP(String phone) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phone,
        codeSent: (String verId, int? resendToken) {
          _verificationId = verId;
          _setLoading(false);
        },
        verificationFailed: (e) {
          _errorMessage = _parseError(e);
          _setLoading(false);
        },
        verificationCompleted: (_) {
          _setLoading(false);
        },
      );
      // verifyPhoneNumber is async but the callbacks handle the result
      // We return true here to indicate the process started, actual success is in codeSent
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) {
      _errorMessage = 'No active verification. Please request a new OTP.';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    _errorMessage = null;
    try {
      // In a pure email/password app, we might just verify the credential to ensure phone ownership,
      // without actually linking it to the user (since they haven't been created yet).
      // Or we can create the credential and if it succeeds, we know the OTP was right.
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      // We don't sign in with this credential, we just verify it exists/is valid.
      // However, Firebase doesn't have a "verify only" method easily exposed.
      // A common pattern is to sign in anonymously or sign in with credential, then link.
      // Since we are doing Email/Password registration, we'll sign in with the phone credential,
      // then later link the email/password, or just use it as a verification step.
      // For simplicity in this flow: we assume if this credential creation doesn't throw, it's a valid code.
      // Actually, to truly verify, we need to sign in.
      await _withTimeout(
        FirebaseAuth.instance.signInWithCredential(credential),
        'Verifying OTP',
      );
      // Now the user is signed in with Phone!
      // We will need to adjust the registration flow to *link* the email instead of creating a new user.
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerOwner({
    required String name,
    required String email,
    required String password,
    required String phone,
    VehicleModel? initialVehicle,
    required GeoSelection geo,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _userModel = await _registerWithRole(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: UserRole.owner,
        initialVehicle: initialVehicle,
        geo: geo,
      );
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerMechanic({
    required String name,
    required String email,
    required String password,
    required String phone,
    required GeoSelection geo,
    // Workshop fields
    required String workshopName,
    required String workshopAddress,
    required String workshopPincode,
    required String openTime,
    required String closeTime,
    required List<String> vehicleTypes,
    required List<String> services,
    required GeoSelection workshopGeo,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _userModel = await _registerWithRole(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: UserRole.mechanic,
        geo: geo,
      );

      // Create the workshop document in Firestore
      if (workshopName.isNotEmpty) {
        final workshopRef =
            FirebaseFirestore.instance.collection('workshops').doc();
        final workshop = WorkshopModel(
          id: workshopRef.id,
          ownerId: _userModel!.uid,
          name: workshopName,
          address: workshopAddress,
          city: workshopGeo.city,
          pincode: workshopPincode,
          vehicleTypes: vehicleTypes,
          services: services,
          openTime: openTime,
          closeTime: closeTime,
          rating: 0.0,
          reviewCount: 0,
          isOpen: true,
          country: workshopGeo.country,
          countryCode: workshopGeo.countryCode,
          state: workshopGeo.state,
          stateCode: workshopGeo.stateCode,
        );
        await _withTimeout(
          workshopRef.set(workshop.toMap()),
          'Creating workshop',
        );
      }

      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Initialize the shared API client with the user's role.
  /// This is a fire-and-forget operation — errors are logged but not surfaced.
  Future<void> _initApiClient(String role) async {
    try {
      await ApiClient.instance.initialize(role);
    } catch (e) {
      debugPrint('ApiClient init failed: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<UserModel> _registerWithRole({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    VehicleModel? initialVehicle,
    required GeoSelection geo,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (_canLinkPhoneRegistration(currentUser, phone)) {
      final phoneUser = currentUser!;
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      var emailLinked = false;
      try {
        await _withTimeout(
          phoneUser.linkWithCredential(credential),
          'Linking account',
        );
        emailLinked = true;
        await _withTimeout(
          phoneUser.updateDisplayName(name),
          'Updating profile',
        );

        final model = UserModel(
          uid: phoneUser.uid,
          name: name,
          email: email.trim(),
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
          country: geo.country,
          countryCode: geo.countryCode,
          state: geo.state,
          stateCode: geo.stateCode,
          city: geo.city,
        );
        await _saveUserProfileAndVehicle(model, initialVehicle);
        return model;
      } catch (_) {
        if (emailLinked) {
          await _deleteCurrentUserOrSignOut(phoneUser);
        } else {
          await _authService.signOut();
        }
        rethrow;
      }
    }

    if (currentUser != null) {
      await _authService.signOut();
    }

    final model = await _authService.registerUser(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
      initialVehicle: initialVehicle,
      geo: geo,
    );
    // Initialize API client with the newly registered user's role
    await _initApiClient(role.name);
    return model;
  }

  Future<T> _withTimeout<T>(Future<T> future, String action) {
    return future.timeout(
      _operationTimeout,
      onTimeout: () {
        throw TimeoutException('$action timed out', _operationTimeout);
      },
    );
  }

  Future<T> _withProfileStorageTimeout<T>(Future<T> future, String action) {
    return future.timeout(
      _profileStorageTimeout,
      onTimeout: () {
        throw TimeoutException(
          '$action timed out. Cloud Firestore may not be enabled for this Firebase project.',
          _profileStorageTimeout,
        );
      },
    );
  }

  String _parseError(Object e) {
    debugPrint('Auth Error Caught: $e');

    if (e is TimeoutException) {
      final message = e.message?.toLowerCase() ?? '';
      if (message.contains('profile') || message.contains('firestore')) {
        return 'Cloud Firestore database is missing for this Firebase project. Create the default Firestore database in Firebase Console, then try again.';
      }
      return 'The request timed out. Please check your internet connection and Firebase setup, then try again.';
    }

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Please sign in instead.';
        case 'provider-already-linked':
          return 'This sign-in method is already linked. Please start registration again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Please use a stronger password.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'credential-already-in-use':
          return 'This phone number is already linked to another account.';
        default:
          return e.message ?? 'Authentication failed. Please try again.';
      }
    }

    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'Firestore permission denied. Please check your Firebase rules.';
        case 'not-found':
          return 'Cloud Firestore database is missing for this Firebase project. Create the default Firestore database in Firebase Console, then try again.';
        case 'unavailable':
          return 'Firebase is currently unavailable. Please try again shortly.';
        default:
          final message = e.message ?? '';
          if (message.toLowerCase().contains('database') &&
              message.toLowerCase().contains('does not exist')) {
            return 'Cloud Firestore database is missing for this Firebase project. Create the default Firestore database in Firebase Console, then try again.';
          }
          return message.isEmpty
              ? 'Firebase request failed. Please try again.'
              : message;
      }
    }

    return 'Something went wrong. Please try again.';
  }

  bool _canLinkPhoneRegistration(User? currentUser, String phone) {
    if (currentUser == null || currentUser.phoneNumber == null) {
      return false;
    }

    final hasPasswordProvider = currentUser.providerData.any(
      (info) => info.providerId == EmailAuthProvider.PROVIDER_ID,
    );
    if (hasPasswordProvider) {
      return false;
    }

    return _normalizePhone(currentUser.phoneNumber!) == _normalizePhone(phone);
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  Future<void> _deleteCurrentUserOrSignOut(User user) async {
    try {
      await _withTimeout(user.delete(), 'Cleaning up account');
    } catch (_) {
      await _authService.signOut();
    }
  }

  Future<void> _saveUserProfileAndVehicle(
    UserModel user,
    VehicleModel? vehicle,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      FirebaseFirestore.instance.collection('users').doc(user.uid),
      user.toMap(),
    );

    if (vehicle != null) {
      batch.set(
        FirebaseFirestore.instance
            .collection('vehicle_owners')
            .doc(user.uid)
            .collection('vehicles')
            .doc(vehicle.id),
        vehicle.toMap(),
      );
    }

    await _withProfileStorageTimeout(batch.commit(), 'Saving profile');
  }
}
