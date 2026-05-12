class AmenityCategory {
  final int id;
  final String name;

  AmenityCategory({
    required this.id,
    required this.name,
  });

  factory AmenityCategory.fromJson(
    Map<String, dynamic> json,
  ) {
    return AmenityCategory(
      id: json["id"],
      name: json["name"],
    );
  }
}