using MeetSpace.Models.Responses;
using MeetSpace.Services.Interfaces;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Data;

namespace MeetSpace.Services.Services
{
    public class AnalyticsService : IAnalyticsService
    {
        private readonly string? _connectionString;

        public AnalyticsService(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("MeetSpaceBI")
                ?? Environment.GetEnvironmentVariable("BI_DB_CONNECTION");
        }

        public async Task<IReadOnlyList<SpaceDemandResponse>> GetSpaceDemandAsync(
            string? cityCode,
            string? facilityCode,
            string? spaceTypeCode,
            string? spaceCode,
            DateTime? fromDate,
            DateTime? toDate,
            CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(_connectionString))
            {
                throw new InvalidOperationException(
                    "The MeetSpaceBI connection is not configured. Set BI_DB_CONNECTION.");
            }

            const string sql = @"
SELECT
    s.SpaceCode,
    s.SpaceName,
    s.FacilityCode,
    s.FacilityName,
    s.CityCode,
    s.CityName,
    s.SpaceTypeCode,
    s.SpaceTypeName,
    COUNT(DISTINCT f.ReservationCode) AS ConfirmedReservations,
    CAST(COALESCE(SUM(f.ReservedHours), 0) AS decimal(12, 2)) AS ReservedHours
FROM bi.DimSpace AS s
LEFT JOIN
(
    SELECT f.SpaceKey, f.ReservationCode, f.ReservedHours, d.DateValue
    FROM bi.FactReservationHour AS f
    INNER JOIN bi.DimDate AS d ON d.DateKey = f.DateKey
    INNER JOIN bi.DimBookingStatus AS st ON st.StatusKey = f.StatusKey
    WHERE st.IsConfirmed = 1
) AS f ON f.SpaceKey = s.SpaceKey
  AND (@FromDate IS NULL OR f.DateValue >= @FromDate)
  AND (@ToDate IS NULL OR f.DateValue <= @ToDate)
WHERE (@CityCode IS NULL OR s.CityCode = @CityCode)
  AND (@FacilityCode IS NULL OR s.FacilityCode = @FacilityCode)
  AND (@SpaceTypeCode IS NULL OR s.SpaceTypeCode = @SpaceTypeCode)
  AND (@SpaceCode IS NULL OR s.SpaceCode = @SpaceCode)
GROUP BY
    s.SpaceCode, s.SpaceName,
    s.FacilityCode, s.FacilityName,
    s.CityCode, s.CityName,
    s.SpaceTypeCode, s.SpaceTypeName
ORDER BY COUNT(DISTINCT f.ReservationCode) DESC, s.SpaceName;";

            await using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync(cancellationToken);

            await using var command = new SqlCommand(sql, connection);
            command.Parameters.Add("@CityCode", SqlDbType.VarChar, 20).Value =
                (object?)cityCode ?? DBNull.Value;
            command.Parameters.Add("@FacilityCode", SqlDbType.VarChar, 30).Value =
                (object?)facilityCode ?? DBNull.Value;
            command.Parameters.Add("@SpaceTypeCode", SqlDbType.VarChar, 30).Value =
                (object?)spaceTypeCode ?? DBNull.Value;
            command.Parameters.Add("@SpaceCode", SqlDbType.VarChar, 40).Value =
                (object?)spaceCode ?? DBNull.Value;
            command.Parameters.Add("@FromDate", SqlDbType.Date).Value =
                (object?)fromDate?.Date ?? DBNull.Value;
            command.Parameters.Add("@ToDate", SqlDbType.Date).Value =
                (object?)toDate?.Date ?? DBNull.Value;

            var results = new List<SpaceDemandResponse>();
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                results.Add(new SpaceDemandResponse
                {
                    SpaceCode = reader.GetString(0),
                    SpaceName = reader.GetString(1),
                    FacilityCode = reader.GetString(2),
                    FacilityName = reader.GetString(3),
                    CityCode = reader.GetString(4),
                    CityName = reader.GetString(5),
                    SpaceTypeCode = reader.GetString(6),
                    SpaceTypeName = reader.GetString(7),
                    ConfirmedReservations = reader.GetInt32(8),
                    ReservedHours = reader.GetDecimal(9)
                });
            }

            return results;
        }

        public async Task<IReadOnlyList<SpaceDemandPeriodResponse>> GetSpaceDemandPeriodsAsync(
            string spaceCode,
            DateTime? fromDate = null,
            DateTime? toDate = null,
            CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(_connectionString))
            {
                throw new InvalidOperationException(
                    "The MeetSpaceBI connection is not configured. Set BI_DB_CONNECTION.");
            }

            const string sql = @"
SELECT
    d.DayOfWeekNumber,
    d.DayOfWeekName,
    h.HourNumber,
    h.HourLabel,
    COUNT(DISTINCT f.ReservationCode) AS ConfirmedReservations
FROM bi.FactReservationHour AS f
INNER JOIN bi.DimSpace AS s ON s.SpaceKey = f.SpaceKey
INNER JOIN bi.DimDate AS d ON d.DateKey = f.DateKey
INNER JOIN bi.DimHour AS h ON h.HourKey = f.HourKey
INNER JOIN bi.DimBookingStatus AS st ON st.StatusKey = f.StatusKey
WHERE s.SpaceCode = @SpaceCode
  AND st.IsConfirmed = 1
  AND (@FromDate IS NULL OR d.DateValue >= @FromDate)
  AND (@ToDate IS NULL OR d.DateValue <= @ToDate)
GROUP BY d.DayOfWeekNumber, d.DayOfWeekName, h.HourNumber, h.HourLabel
ORDER BY ConfirmedReservations DESC, d.DayOfWeekNumber, h.HourNumber;";

            await using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync(cancellationToken);
            await using var command = new SqlCommand(sql, connection);
            command.Parameters.Add("@SpaceCode", SqlDbType.VarChar, 40).Value = spaceCode;
            command.Parameters.Add("@FromDate", SqlDbType.Date).Value =
                (object?)fromDate?.Date ?? DBNull.Value;
            command.Parameters.Add("@ToDate", SqlDbType.Date).Value =
                (object?)toDate?.Date ?? DBNull.Value;

            var results = new List<SpaceDemandPeriodResponse>();
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                results.Add(new SpaceDemandPeriodResponse
                {
                    DayOfWeekNumber = reader.GetByte(0),
                    DayOfWeekName = reader.GetString(1),
                    HourNumber = reader.GetByte(2),
                    HourLabel = reader.GetString(3),
                    ConfirmedReservations = reader.GetInt32(4)
                });
            }

            return results;
        }
    }
}
