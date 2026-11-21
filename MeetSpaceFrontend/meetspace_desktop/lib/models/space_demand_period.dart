class SpaceDemandPeriod {
  final int dayOfWeekNumber;
  final String dayOfWeekName;
  final int hourNumber;
  final String hourLabel;
  final int confirmedReservations;

  const SpaceDemandPeriod({
    required this.dayOfWeekNumber,
    required this.dayOfWeekName,
    required this.hourNumber,
    required this.hourLabel,
    required this.confirmedReservations,
  });

  factory SpaceDemandPeriod.fromJson(Map<String, dynamic> json) {
    return SpaceDemandPeriod(
      dayOfWeekNumber: (json['dayOfWeekNumber'] as num?)?.toInt() ?? 0,
      dayOfWeekName: json['dayOfWeekName'] as String? ?? '',
      hourNumber: (json['hourNumber'] as num?)?.toInt() ?? 0,
      hourLabel: json['hourLabel'] as String? ?? '',
      confirmedReservations:
          (json['confirmedReservations'] as num?)?.toInt() ?? 0,
    );
  }
}
