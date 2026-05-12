class SpaceType {
  final int id;

  final String name;

  SpaceType({
    required this.id,
    required this.name,
  });

  factory SpaceType.fromJson(
    Map<String, dynamic> json,
  ) {
    return SpaceType(
      id: json["id"],
      name: json["name"] ?? "",
    );
  }
}