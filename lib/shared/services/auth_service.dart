import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mechmate_app/core/constants/constants.dart';
import 'package:mechmate_app/features/auth/models/user_model.dart';
import 'package:mechmate_app/features/owner/models/vehicle_model.dart';

import 'package:mechmate_app/shared/widgets/widgets.dart';

class AuthService {
  static const Duration _authOperationTimeout = Duration(seconds: 20);
  static const Duration _firestoreOperationTimeout = Duration(seconds: 8);

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return Stream.value(null);
    }
  }

  Future<UserModel?> signIn(
    String email,
    String password, [
    UserRole? mockRole,
  ]) async {
    final cred = await _withTimeout(
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password),
      'Signing in',
    );
    if (cred.user != null) {
      return getUserModel(cred.user!.uid);
    }
    return null;
  }

  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    VehicleModel? initialVehicle,
    required GeoSelection geo,
  }) async {
    UserCredential? cred;
    try {
      final userCredential = await _withTimeout(
        _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
        'Creating account',
      );
      cred = userCredential;
      final createdUser = userCredential.user!;
      await _withTimeout(
        createdUser.updateDisplayName(name),
        'Updating profile',
      );
      final uid = createdUser.uid;
      final model = UserModel(
        uid: uid,
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
      final createdUser = cred?.user;
      if (createdUser != null) {
        await _deleteCreatedUserOrSignOut(createdUser);
      }
      rethrow;
    }
  }

  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _withFirestoreTimeout(
      _db.collection('users').doc(uid).get(),
      'Loading profile',
    );
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> signOut() async {
    await _withTimeout(_auth.signOut(), 'Signing out');
  }

  Future<void> resetPassword(String email) async {
    await _withTimeout(
      _auth.sendPasswordResetEmail(email: email.trim()),
      'Sending reset email',
    );
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
  }) async {
    await _withTimeout(
      _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: _authOperationTimeout,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: (String verificationId) {},
      ),
      'Sending OTP',
    );
  }

  Future<T> _withTimeout<T>(Future<T> future, String action) {
    return future.timeout(
      _authOperationTimeout,
      onTimeout: () {
        throw TimeoutException('$action timed out', _authOperationTimeout);
      },
    );
  }

  Future<T> _withFirestoreTimeout<T>(Future<T> future, String action) {
    return future.timeout(
      _firestoreOperationTimeout,
      onTimeout: () {
        throw TimeoutException(
          '$action timed out. Cloud Firestore may not be enabled for this Firebase project.',
          _firestoreOperationTimeout,
        );
      },
    );
  }

  Future<void> _saveUserProfileAndVehicle(
    UserModel user,
    VehicleModel? vehicle,
  ) async {
    final batch = _db.batch();
    batch.set(_db.collection('users').doc(user.uid), user.toMap());

    if (vehicle != null) {
      batch.set(
        _db
            .collection('vehicle_owners')
            .doc(user.uid)
            .collection('vehicles')
            .doc(vehicle.id),
        vehicle.toMap(),
      );
    }

    await _withFirestoreTimeout(batch.commit(), 'Saving profile');
  }

  Future<void> _deleteCreatedUserOrSignOut(User user) async {
    try {
      await _withTimeout(user.delete(), 'Cleaning up account');
    } catch (_) {
      await _auth.signOut();
    }
  }
}
