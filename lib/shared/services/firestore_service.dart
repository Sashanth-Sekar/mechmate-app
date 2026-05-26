import 'package:mechmate_app/features/owner/owner.dart';
import 'package:mechmate_app/features/mechanic/mechanic.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static const Duration _operationTimeout = Duration(seconds: 8);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Vehicles ──────────────────────────────────────────────────────────────
  Future<void> addVehicle(String userId, VehicleModel vehicle) async {
    await _withTimeout(
      _db
          .collection('vehicle_owners')
          .doc(userId)
          .collection('vehicles')
          .doc(vehicle.id)
          .set(vehicle.toMap()),
      'Saving vehicle',
    );
  }

  Future<List<VehicleModel>> getVehicles(String userId) async {
    final snap = await _withTimeout(
      _db.collection('vehicle_owners').doc(userId).collection('vehicles').get(),
      'Loading vehicles',
    );
    return snap.docs.map((d) => VehicleModel.fromMap(d.data())).toList();
  }

  Future<void> deleteVehicle(String userId, String vehicleId) async {
    await _withTimeout(
      _db
          .collection('vehicle_owners')
          .doc(userId)
          .collection('vehicles')
          .doc(vehicleId)
          .delete(),
      'Deleting vehicle',
    );
  }

  // ── Workshops ─────────────────────────────────────────────────────────────
  Future<void> saveWorkshop(WorkshopModel workshop) async {
    await _db.collection('workshops').doc(workshop.id).set(workshop.toMap());
  }

  Future<List<WorkshopModel>> getWorkshops() async {
    final snap = await _db.collection('workshops').limit(50).get();
    return snap.docs.map((d) => WorkshopModel.fromMap(d.data())).toList();
  }

  Future<WorkshopModel?> getWorkshopByOwner(String ownerId) async {
    final snap = await _db
        .collection('workshops')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return WorkshopModel.fromMap(snap.docs.first.data());
  }

  Future<void> updateWorkshopStatus(String workshopId, bool isOpen) async {
    await _db.collection('workshops').doc(workshopId).update({
      'isOpen': isOpen,
    });
  }

  // ── Bookings ──────────────────────────────────────────────────────────────
  Future<String> createBooking(BookingModel booking) async {
    final ref = _db.collection('bookings').doc();
    final updated = BookingModel(
      id: ref.id,
      ownerId: booking.ownerId,
      workshopId: booking.workshopId,
      workshopName: booking.workshopName,
      service: booking.service,
      vehicleType: booking.vehicleType,
      vehicleNumber: booking.vehicleNumber,
      vehicleMake: booking.vehicleMake,
      vehicleModel: booking.vehicleModel,
      scheduledAt: booking.scheduledAt,
      status: booking.status,
      notes: booking.notes,
      createdAt: booking.createdAt,
    );
    await ref.set(updated.toMap());
    return ref.id;
  }

  Future<List<BookingModel>> getOwnerBookings(String ownerId) async {
    final snap = await _db
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => BookingModel.fromMap(d.data())).toList();
  }

  Future<List<BookingModel>> getWorkshopBookings(String workshopId) async {
    final snap = await _db
        .collection('bookings')
        .where('workshopId', isEqualTo: workshopId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => BookingModel.fromMap(d.data())).toList();
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _db.collection('bookings').doc(bookingId).update({'status': status});
  }

  // ── Job Cards ─────────────────────────────────────────────────────────────
  Future<void> createJobCard(JobCardModel job) async {
    await _db.collection('job_cards').doc(job.id).set(job.toMap());
  }

  Future<List<JobCardModel>> getWorkshopActiveJobs(String workshopId) async {
    final snap = await _db
        .collection('job_cards')
        .where('workshopId', isEqualTo: workshopId)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.map((d) => JobCardModel.fromMap(d.data())).toList();
  }

  Future<void> completeJobCard(String jobId) async {
    await _db.collection('job_cards').doc(jobId).update({
      'status': 'completed',
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<T> _withTimeout<T>(Future<T> future, String action) {
    return future.timeout(
      _operationTimeout,
      onTimeout: () {
        throw TimeoutException('$action timed out', _operationTimeout);
      },
    );
  }
}
