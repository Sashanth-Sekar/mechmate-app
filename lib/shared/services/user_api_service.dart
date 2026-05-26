import 'package:mechmate_app/features/auth/models/user_model.dart';
import 'package:mechmate_app/shared/services/api_client.dart';

class UserApiService {
  final ApiClient _client;

  /// Uses the global [ApiClient.instance] singleton by default.
  UserApiService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Fetch the current user's profile.
  Future<UserModel> getProfile() async {
    return _client.get(
      '/users/profile',
      fromJson: (data) => UserModel.fromMap(data),
    );
  }

  /// Update the current user's profile.
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? city,
    String? state,
    String? country,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (city != null) body['city'] = city;
    if (state != null) body['state'] = state;
    if (country != null) body['country'] = country;

    return _client.post(
      '/users/profile',
      body: body,
      fromJson: (data) => UserModel.fromMap(data),
    );
  }
}
