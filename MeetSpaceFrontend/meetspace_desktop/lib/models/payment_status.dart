class PaymentStatus {
  final int id;

  final String name;

  PaymentStatus({
    required this.id,
    required this.name,
  });

  factory PaymentStatus.fromJson(
    Map<String, dynamic> json,
  ) {
    return PaymentStatus(
      id: json["id"],
      name: json["name"] ?? "",
    );
  }
}