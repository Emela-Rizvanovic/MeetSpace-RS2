class BookingResponse {
  final int id;
  final int spaceId;
  final int userId;
  final int bookingStatusId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;

  final String? spaceName;
  final String? statusName;
  final String? facilityAddress;
  final String? rejectionReason;
  final bool isPaid;

  BookingResponse({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.bookingStatusId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    this.spaceName,
    this.statusName,
    this.facilityAddress,
    this.rejectionReason,
    required this.isPaid,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      id: (json['id'] ?? 0) as int,
      spaceId: (json['spaceId'] ?? 0) as int,
      userId: (json['userId'] ?? 0) as int,
      bookingStatusId: (json['bookingStatusId'] ?? 0) as int,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      totalPrice: (json['totalPrice'] is int)
          ? (json['totalPrice'] as int).toDouble()
          : (json['totalPrice'] ?? 0.0) as double,
      spaceName: json['spaceName']?.toString(),
      statusName: json['statusName']?.toString(),
      facilityAddress: json['facilityAddress']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      isPaid: json['isPaid'] == true,
    );
  }
}
