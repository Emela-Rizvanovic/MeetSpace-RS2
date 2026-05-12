class BookingStatus {
  final int id;
  final String name;

  BookingStatus({
    required this.id,
    required this.name,
  });

  factory BookingStatus.fromJson(
    Map<String, dynamic> json,
  ) {
    return BookingStatus(
      id: json["id"],
      name: json["name"] ?? "",
    );
  }
}