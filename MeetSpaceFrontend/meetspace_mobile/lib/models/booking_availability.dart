class BookingAvailabilityResponse {
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  BookingAvailabilityResponse({
    required this.startTime,
    required this.endTime,
    required this.status,
  });

factory BookingAvailabilityResponse.fromJson(Map<String, dynamic> json) {
  final start = json['startTime'] ?? json['StartTime'];
  final end = json['endTime'] ?? json['EndTime'];
  final status = json['status'] ?? json['Status'] ?? 'busy';

  return BookingAvailabilityResponse(
    startTime: DateTime.parse(start.toString()),
    endTime: DateTime.parse(end.toString()),
    status: status.toString(),
  );
}
}