import 'package:mechmate_app/features/owner/models/vehicle_model.dart';
import 'package:mechmate_app/shared/services/api_client.dart';

class VehicleApiService {
  final ApiClient _client;

  /// Uses the global [ApiClient.instance] singleton by default.
  VehicleApiService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Fetch all vehicles for the currently authenticated user.
  Future<List<VehicleModel>> getVehicles() async {
    return _client.getList(
      '/vehicles',
      fromJson: (data) => VehicleModel.fromMap(data),
    );
  }

  /// Add a new vehicle.
  Future<VehicleModel> addVehicle(VehicleModel vehicle) async {
    return _client.post(
      '/vehicles',
      body: vehicle.toCreatePayload(),
      fromJson: (data) => VehicleModel.fromMap(data),
    );
  }

  /// Delete a vehicle by ID.
  Future<void> deleteVehicle(String id) async {
    await _client.delete('/vehicles/$id');
  }
}
