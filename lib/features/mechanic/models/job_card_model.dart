class JobCardModel {
  final String id;
  final String bookingId;
  final String workshopId;
  final String customerName;
  final String vehicleType;
  final String vehicleNumber;
  final String vehicleMake;
  final String vehicleModel;
  final String service;
  final List<String> partsUsed;
  final String? labourNotes;
  final String status; // 'active' | 'completed'
  final DateTime createdAt;
  final DateTime? completedAt;

  const JobCardModel({
    required this.id,
    required this.bookingId,
    required this.workshopId,
    required this.customerName,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.service,
    required this.partsUsed,
    this.labourNotes,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookingId': bookingId,
        'workshopId': workshopId,
        'customerName': customerName,
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        'vehicleMake': vehicleMake,
        'vehicleModel': vehicleModel,
        'service': service,
        'partsUsed': partsUsed,
        'labourNotes': labourNotes,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory JobCardModel.fromMap(Map<String, dynamic> map) => JobCardModel(
        id: map['id'] as String? ?? '',
        bookingId: map['bookingId'] as String? ?? '',
        workshopId: map['workshopId'] as String? ?? '',
        customerName: map['customerName'] as String? ?? '',
        vehicleType: map['vehicleType'] as String? ?? '',
        vehicleNumber: map['vehicleNumber'] as String? ?? '',
        vehicleMake: map['vehicleMake'] as String? ?? '',
        vehicleModel: map['vehicleModel'] as String? ?? '',
        service: map['service'] as String? ?? '',
        partsUsed: List<String>.from(map['partsUsed'] as List? ?? []),
        labourNotes: map['labourNotes'] as String?,
        status: map['status'] as String? ?? 'active',
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                DateTime.now(),
        completedAt: map['completedAt'] != null
            ? DateTime.tryParse(map['completedAt'] as String)
            : null,
      );
}
