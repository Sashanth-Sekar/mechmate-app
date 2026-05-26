class BookingModel {
  final String id;
  final String ownerId;
  final String workshopId;
  final String workshopName;
  final String service;
  final String vehicleType;
  final String vehicleNumber;
  final String vehicleMake;
  final String vehicleModel;
  final DateTime scheduledAt;
  final String status;
  final String? notes;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.ownerId,
    required this.workshopId,
    required this.workshopName,
    required this.service,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.scheduledAt,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerId': ownerId,
    'workshopId': workshopId,
    'workshopName': workshopName,
    'service': service,
    'vehicleType': vehicleType,
    'vehicleNumber': vehicleNumber,
    'vehicleMake': vehicleMake,
    'vehicleModel': vehicleModel,
    'scheduledAt': scheduledAt.toIso8601String(),
    'status': status,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BookingModel.fromMap(Map<String, dynamic> map) => BookingModel(
    id: map['id'] as String? ?? '',
    ownerId: map['ownerId'] as String? ?? '',
    workshopId: map['workshopId'] as String? ?? '',
    workshopName: map['workshopName'] as String? ?? '',
    service: map['service'] as String? ?? '',
    vehicleType: map['vehicleType'] as String? ?? '',
    vehicleNumber: map['vehicleNumber'] as String? ?? '',
    vehicleMake: map['vehicleMake'] as String? ?? '',
    vehicleModel: map['vehicleModel'] as String? ?? '',
    scheduledAt:
        DateTime.tryParse(map['scheduledAt'] as String? ?? '') ??
        DateTime.now(),
    status: map['status'] as String? ?? 'pending',
    notes: map['notes'] as String?,
    createdAt:
        DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  BookingModel copyWith({String? status}) => BookingModel(
    id: id,
    ownerId: ownerId,
    workshopId: workshopId,
    workshopName: workshopName,
    service: service,
    vehicleType: vehicleType,
    vehicleNumber: vehicleNumber,
    vehicleMake: vehicleMake,
    vehicleModel: vehicleModel,
    scheduledAt: scheduledAt,
    status: status ?? this.status,
    notes: notes,
    createdAt: createdAt,
  );
}
