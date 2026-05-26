// Fake VehicleApiService for widget tests.
//
// Returns mock vehicle data without any network or Firebase dependency.
// Uses `implements` instead of `extends` because the real constructor
// requires a non-mock [ApiClient].

import 'package:mechmate_app/features/owner/models/vehicle_model.dart';
import 'package:mechmate_app/shared/services/services.dart';

// ===================================================================
// Fake VehicleApiService
// ===================================================================

/// Fake implementation of [VehicleApiService] that returns mock vehicle data
/// without any network or Firebase dependency.  Uses `implements` instead of
/// `extends` because the real constructor requires a non-mock [ApiClient].
class FakeVehicleApiService implements VehicleApiService {
  List<VehicleModel> _vehicles = [];

  // Per-method error messages. When non-null the corresponding method
  // throws [ApiException] with that message on every invocation.
  String? _getErrorMessage;
  String? _addErrorMessage;
  String? _deleteErrorMessage;

  int getVehiclesCallCount = 0;
  int addVehicleCallCount = 0;
  int deleteVehicleCallCount = 0;

  /// Configure which vehicles to return from [getVehicles].
  void setVehicles(List<VehicleModel> vehicles) {
    _vehicles = vehicles;
  }

  /// [getVehicles] will throw [ApiException] with [message].
  void setGetFailure(String message) {
    _getErrorMessage = message;
  }

  /// [addVehicle] will throw [ApiException] with [message].
  void setAddFailure(String message) {
    _addErrorMessage = message;
  }

  /// [deleteVehicle] will throw [ApiException] with [message].
  void setDeleteFailure(String message) {
    _deleteErrorMessage = message;
  }

  /// Reset all methods back to success mode.
  void clearFailures() {
    _getErrorMessage = null;
    _addErrorMessage = null;
    _deleteErrorMessage = null;
  }

  @override
  Future<List<VehicleModel>> getVehicles() async {
    getVehiclesCallCount++;
    if (_getErrorMessage != null) {
      throw ApiException(_getErrorMessage!);
    }
    return List.unmodifiable(_vehicles);
  }

  @override
  Future<VehicleModel> addVehicle(VehicleModel vehicle) async {
    addVehicleCallCount++;
    if (_addErrorMessage != null) {
      throw ApiException(_addErrorMessage!);
    }
    _vehicles = [..._vehicles, vehicle];
    return vehicle;
  }

  @override
  Future<void> deleteVehicle(String id) async {
    deleteVehicleCallCount++;
    if (_deleteErrorMessage != null) {
      throw ApiException(_deleteErrorMessage!);
    }
    _vehicles = _vehicles.where((v) => v.id != id).toList();
  }
}
