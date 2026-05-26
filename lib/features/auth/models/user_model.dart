import 'package:mechmate_app/core/constants/constants.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final DateTime createdAt;

  // Required during registration
  final String country;
  final String countryCode;
  final String state;
  final String stateCode;
  final String city;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
    required this.country,
    required this.countryCode,
    required this.state,
    required this.stateCode,
    required this.city,
  });

  UserModel.empty()
      : uid = '',
        name = '',
        email = '',
        phone = '',
        role = UserRole.owner,
        createdAt = DateTime.fromMillisecondsSinceEpoch(0),
        country = '',
        countryCode = '',
        state = '',
        stateCode = '',
        city = '';

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
        'country': country,
        'countryCode': countryCode,
        'state': state,
        'stateCode': stateCode,
        'city': city,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.name == (map['role'] as String? ?? ''),
          orElse: () => UserRole.owner,
        ),
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                DateTime.now(),
        country: map['country'] as String? ?? '',
        countryCode: map['countryCode'] as String? ?? '',
        state: map['state'] as String? ?? '',
        stateCode: map['stateCode'] as String? ?? '',
        city: map['city'] as String? ?? '',
      );

  UserModel copyWith({
    String? name,
    String? phone,
    String? country,
    String? countryCode,
    String? state,
    String? stateCode,
    String? city,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        role: role,
        createdAt: createdAt,
        country: country ?? this.country,
        countryCode: countryCode ?? this.countryCode,
        state: state ?? this.state,
        stateCode: stateCode ?? this.stateCode,
        city: city ?? this.city,
      );
}
