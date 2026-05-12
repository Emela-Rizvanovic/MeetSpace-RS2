class Facility {
  final int id;

  final String name;
  final String address;

  final int cityId;

  final String cityName;
  final String countryName;

  final String? description;
  final String? contactEmail;
  final String? contactPhone;

  Facility({
    required this.id,
    required this.name,
    required this.address,
    required this.cityId,
    required this.cityName,
    required this.countryName,
    this.description,
    this.contactEmail,
    this.contactPhone,
  });

  factory Facility.fromJson(
    Map<String, dynamic> json,
  ) {
    return Facility(
      id: json["id"],

      name: json["name"] ?? "",

      address: json["address"] ?? "",

      cityId: json["cityId"],

      cityName:
          json["cityName"] ?? "",

      countryName:
          json["countryName"] ?? "",

      description:
          json["description"],

      contactEmail:
          json["contactEmail"],

      contactPhone:
          json["contactPhone"],
    );
  }
}