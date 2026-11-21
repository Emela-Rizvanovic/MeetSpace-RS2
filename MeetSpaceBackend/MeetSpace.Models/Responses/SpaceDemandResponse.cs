namespace MeetSpace.Models.Responses
{
    public class SpaceDemandResponse
    {
        public string SpaceCode { get; set; } = string.Empty;
        public string SpaceName { get; set; } = string.Empty;
        public string FacilityCode { get; set; } = string.Empty;
        public string FacilityName { get; set; } = string.Empty;
        public string CityCode { get; set; } = string.Empty;
        public string CityName { get; set; } = string.Empty;
        public string SpaceTypeCode { get; set; } = string.Empty;
        public string SpaceTypeName { get; set; } = string.Empty;
        public int ConfirmedReservations { get; set; }
        public decimal ReservedHours { get; set; }
    }

    public class SpaceDemandPeriodResponse
    {
        public int DayOfWeekNumber { get; set; }
        public string DayOfWeekName { get; set; } = string.Empty;
        public int HourNumber { get; set; }
        public string HourLabel { get; set; } = string.Empty;
        public int ConfirmedReservations { get; set; }
    }
}
