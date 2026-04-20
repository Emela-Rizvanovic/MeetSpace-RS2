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
  final String? username;
  final String? spaceImageUrl;
  final String? userFullName;
final String? userEmail;
final String? userPhone;
final String? rejectionReason;
final String? paymentStatusName;
String? lastAction;
String? lastAdminName;
DateTime? lastActionAt;

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
    this.username,
    this.spaceImageUrl,
    this.userFullName,
    this.userEmail,
    this.userPhone,
    this.rejectionReason,
    this.paymentStatusName,
    this.lastAction,
    this.lastAdminName,
    this.lastActionAt
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
      username: json['username']?.toString(),
      spaceImageUrl: json['spaceImageUrl']?.toString(),
      userFullName: json['userFullName'],
userEmail: json['userEmail'],
userPhone: json['userPhone'],
rejectionReason: json['rejectionReason'],
paymentStatusName: json['paymentStatusName'],
lastAction: json['lastAction'],
lastAdminName: json['lastAdminName'],
lastActionAt : json['lastActionAt'] != null
    ? DateTime.parse(json['lastActionAt'])
    : null
    );
  }
}
