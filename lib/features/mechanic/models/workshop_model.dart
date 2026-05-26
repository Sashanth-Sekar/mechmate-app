class WorkshopModel {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final String city;
  final String pincode;
  final List<String> vehicleTypes;
  final List<String> services;
  final String openTime;
  final String closeTime;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final String? phone;

  // Geographic location fields
  final double latitude;
  final double longitude;
  final String country;
  final String countryCode;
  final String state;
  final String stateCode;

  const WorkshopModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.city,
    required this.pincode,
    required this.vehicleTypes,
    required this.services,
    required this.openTime,
    required this.closeTime,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    this.phone,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.country = '',
    this.countryCode = '',
    this.state = '',
    this.stateCode = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
        'address': address,
        'city': city,
        'pincode': pincode,
        'vehicleTypes': vehicleTypes,
        'services': services,
        'openTime': openTime,
        'closeTime': closeTime,
        'rating': rating,
        'reviewCount': reviewCount,
        'isOpen': isOpen,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'country': country,
        'countryCode': countryCode,
        'state': state,
        'stateCode': stateCode,
      };

  factory WorkshopModel.fromMap(Map<String, dynamic> map) => WorkshopModel(
        id: map['id'] as String? ?? '',
        ownerId: map['ownerId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        address: map['address'] as String? ?? '',
        city: map['city'] as String? ?? '',
        pincode: map['pincode'] as String? ?? '',
        vehicleTypes:
            List<String>.from(map['vehicleTypes'] as List? ?? []),
        services: List<String>.from(map['services'] as List? ?? []),
        openTime: map['openTime'] as String? ?? '09:00',
        closeTime: map['closeTime'] as String? ?? '18:00',
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
        isOpen: map['isOpen'] as bool? ?? true,
        phone: map['phone'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
        country: map['country'] as String? ?? '',
        countryCode: map['countryCode'] as String? ?? '',
        state: map['state'] as String? ?? '',
        stateCode: map['stateCode'] as String? ?? '',
      );

  WorkshopModel copyWith({
    bool? isOpen,
    String? name,
    String? country,
    String? countryCode,
    String? state,
    String? stateCode,
    String? city,
  }) =>
      WorkshopModel(
        id: id,
        ownerId: ownerId,
        name: name ?? this.name,
        address: address,
        city: city ?? this.city,
        pincode: pincode,
        vehicleTypes: vehicleTypes,
        services: services,
        openTime: openTime,
        closeTime: closeTime,
        rating: rating,
        reviewCount: reviewCount,
        isOpen: isOpen ?? this.isOpen,
        phone: phone,
        country: country ?? this.country,
        countryCode: countryCode ?? this.countryCode,
        state: state ?? this.state,
        stateCode: stateCode ?? this.stateCode,
      );
}
