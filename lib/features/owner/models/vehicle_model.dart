class VehicleModel {
  final String id;
  final String type; // 'Car' or 'Bike'
  final String number;
  final String make;
  final String model;
  final int year;
  final String? color;
  final String? fuelType;
  final String? registrationNumber;
  final int? odometerReading;
  final String? insuranceDetails;
  final String? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VehicleModel({
    required this.id,
    required this.type,
    required this.number,
    required this.make,
    required this.model,
    required this.year,
    this.color,
    this.fuelType,
    this.registrationNumber,
    this.odometerReading,
    this.insuranceDetails,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'number': number,
    'make': make,
    'model': model,
    'year': year,
    'color': color,
    'fuelType': fuelType,
    'registrationNumber': registrationNumber,
    'odometerReading': odometerReading,
    'insuranceDetails': insuranceDetails,
    'ownerId': ownerId,
  };

  /// Create a payload suitable for the backend POST /vehicles endpoint.
  Map<String, dynamic> toCreatePayload() => {
    'type': type,
    'number': number,
    'make': make,
    'model': model,
    'year': year,
    if (color != null) 'color': color,
    if (fuelType != null) 'fuelType': fuelType,
    if (registrationNumber != null) 'registrationNumber': registrationNumber,
    if (odometerReading != null) 'odometerReading': odometerReading,
    if (insuranceDetails != null) 'insuranceDetails': insuranceDetails,
  };

  factory VehicleModel.fromMap(Map<String, dynamic> map) => VehicleModel(
    id: map['id'] as String? ?? '',
    type: map['type'] as String? ?? 'Car',
    number: map['number'] as String? ?? '',
    make: map['make'] as String? ?? '',
    model: map['model'] as String? ?? '',
    year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
    color: map['color'] as String?,
    fuelType: map['fuelType'] as String?,
    registrationNumber: map['registrationNumber'] as String?,
    odometerReading: (map['odometerReading'] as num?)?.toInt(),
    insuranceDetails: map['insuranceDetails'] as String?,
    ownerId: map['ownerId'] as String?,
    createdAt: map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt'] as String)
        : null,
    updatedAt: map['updatedAt'] != null
        ? DateTime.tryParse(map['updatedAt'] as String)
        : null,
  );
}
