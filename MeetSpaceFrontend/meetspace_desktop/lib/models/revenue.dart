class RevenueResponse {
  final double amount;
  final String user;
  final String location;
  final String paymentMethod;
  final DateTime date;

  RevenueResponse({
    required this.amount,
    required this.user,
    required this.location,
    required this.paymentMethod,
    required this.date,
  });

  factory RevenueResponse.fromJson(Map<String, dynamic> json) {
    return RevenueResponse(
      amount: (json['amount'] as num).toDouble(),
      user: json['user'] ?? '',
      location: json['location'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      date: DateTime.parse(json['date']),
    );
  }
}