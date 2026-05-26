import 'package:mechmate_app/features/mechanic/models/workshop_model.dart';
import 'package:mechmate_app/shared/services/api_client.dart';

class WorkshopApiService {
  final ApiClient _client;

  /// Uses the global [ApiClient.instance] singleton by default.
  WorkshopApiService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Fetch nearby workshops (for owners to browse).
  Future<List<WorkshopModel>> getNearbyWorkshops({
    double? lat,
    double? lng,
    double? radiusKm,
    String? query,
  }) async {
    final params = <String, String>{};
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();
    if (radiusKm != null) params['radius'] = radiusKm.toString();
    if (query != null && query.isNotEmpty) params['q'] = query;

    final qs =
        params.isNotEmpty
            ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}'
            : '';

    return _client.getList(
      '/workshops$qs',
      fromJson: (data) => WorkshopModel.fromMap(data),
    );
  }

  /// Fetch a single workshop by ID.
  Future<WorkshopModel> getWorkshop(String id) async {
    return _client.get(
      '/workshops/$id',
      fromJson: (data) => WorkshopModel.fromMap(data),
    );
  }

  /// Fetch workshop owned by the current mechanic.
  Future<WorkshopModel?> getMyWorkshop() async {
    try {
      return await _client.get(
        '/workshops/mine',
        fromJson: (data) => WorkshopModel.fromMap(data),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Create a new workshop.
  Future<WorkshopModel> createWorkshop(WorkshopModel workshop) async {
    return _client.post(
      '/workshops',
      body: workshop.toMap()..remove('id'),
      fromJson: (data) => WorkshopModel.fromMap(data),
    );
  }

  /// Update workshop status (open/closed).
  Future<void> updateStatus(String workshopId, bool isOpen) async {
    await _client.patch<void>(
      '/workshops/$workshopId',
      body: {'isOpen': isOpen},
    );
  }

  /// Update full workshop profile.
  Future<WorkshopModel> updateWorkshop(String workshopId, Map<String, dynamic> data) async {
    final result = await _client.patch<Map<String, dynamic>>(
      '/workshops/$workshopId',
      body: data,
      fromJson: (data) => data,
    );
    return WorkshopModel.fromMap(result!);
  }
}
