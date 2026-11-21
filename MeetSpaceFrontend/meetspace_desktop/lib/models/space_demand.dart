class SpaceDemand {
  final String spaceCode;
  final String spaceName;
  final String facilityCode;
  final String facilityName;
  final String cityCode;
  final String cityName;
  final String spaceTypeCode;
  final String spaceTypeName;
  final int confirmedReservations;
  final double reservedHours;

  const SpaceDemand({
    required this.spaceCode,
    required this.spaceName,
    required this.facilityCode,
    required this.facilityName,
    required this.cityCode,
    required this.cityName,
    required this.spaceTypeCode,
    required this.spaceTypeName,
    required this.confirmedReservations,
    required this.reservedHours,
  });

  factory SpaceDemand.fromJson(Map<String, dynamic> json) {
    return SpaceDemand(
      spaceCode: json['spaceCode'] as String? ?? '',
      spaceName: json['spaceName'] as String? ?? '',
      facilityCode: json['facilityCode'] as String? ?? '',
      facilityName: json['facilityName'] as String? ?? '',
      cityCode: json['cityCode'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      spaceTypeCode: json['spaceTypeCode'] as String? ?? '',
      spaceTypeName: json['spaceTypeName'] as String? ?? '',
      confirmedReservations: (json['confirmedReservations'] as num?)?.toInt() ?? 0,
      reservedHours: (json['reservedHours'] as num?)?.toDouble() ?? 0,
    );
  }
}
