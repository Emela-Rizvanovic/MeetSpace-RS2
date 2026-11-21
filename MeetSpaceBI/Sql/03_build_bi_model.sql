/*
  Build the MeetSpaceBI dimensional model from the loaded staging tables.
  Fact grain: one row for each reservation within each hourly interval it touches.
  This script writes only to the separate MeetSpaceBI database.
*/

USE [MeetSpaceBI];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS (SELECT 1 FROM [bi].[DimSpace])
   OR EXISTS (SELECT 1 FROM [bi].[DimDate])
   OR EXISTS (SELECT 1 FROM [bi].[FactReservationHour])
BEGIN
    RAISERROR(N'The BI model already contains rows. No changes were made; inspect the BI tables before continuing.', 16, 1);
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO [bi].[DimSpace]
    (
        SpaceCode, SpaceName, FacilityCode, FacilityName, Address,
        CityCode, CityName, SpaceTypeCode, SpaceTypeName, Capacity, MeetSpaceSpaceId
    )
    SELECT
        s.SpaceCode,
        s.SpaceName,
        f.FacilityCode,
        f.FacilityName,
        f.Address,
        c.CityCode,
        c.CityName,
        t.SpaceTypeCode,
        t.SpaceTypeName,
        s.Capacity,
        s.MeetSpaceSpaceId
    FROM [stg].[Space] AS s
    INNER JOIN [stg].[Facility] AS f ON f.FacilityCode = s.FacilityCode
    INNER JOIN [stg].[City] AS c ON c.CityCode = f.CityCode
    INNER JOIN [stg].[SpaceType] AS t ON t.SpaceTypeCode = s.SpaceTypeCode;

    ;WITH Bounds AS
    (
        SELECT
            MIN(CONVERT(date, StartDateTime)) AS MinDate,
            MAX(CONVERT(date, EndDateTime)) AS MaxDate
        FROM [stg].[Reservation]
    ), Calendar AS
    (
        SELECT MinDate AS DateValue
        FROM Bounds
        WHERE MinDate IS NOT NULL
        UNION ALL
        SELECT DATEADD(day, 1, Calendar.DateValue)
        FROM Calendar
        CROSS JOIN Bounds
        WHERE Calendar.DateValue < Bounds.MaxDate
    )
    INSERT INTO [bi].[DimDate]
    (
        DateKey, DateValue, CalendarYear, MonthNumber, MonthName,
        DayOfMonth, DayOfWeekNumber, DayOfWeekName, IsWeekend, AcademicPeriodLabel
    )
    SELECT
        CONVERT(int, CONVERT(char(8), DateValue, 112)),
        DateValue,
        CONVERT(smallint, DATEPART(year, DateValue)),
        CONVERT(tinyint, DATEPART(month, DateValue)),
        CASE DATEPART(month, DateValue)
            WHEN 1 THEN N'Januar' WHEN 2 THEN N'Februar' WHEN 3 THEN N'Mart'
            WHEN 4 THEN N'April' WHEN 5 THEN N'Maj' WHEN 6 THEN N'Juni'
            WHEN 7 THEN N'Juli' WHEN 8 THEN N'August' WHEN 9 THEN N'Septembar'
            WHEN 10 THEN N'Oktobar' WHEN 11 THEN N'Novembar' WHEN 12 THEN N'Decembar'
        END,
        CONVERT(tinyint, DATEPART(day, DateValue)),
        CONVERT(tinyint, (DATEDIFF(day, CONVERT(date, '19000101', 112), DateValue) % 7) + 1),
        CASE (DATEDIFF(day, CONVERT(date, '19000101', 112), DateValue) % 7) + 1
            WHEN 1 THEN N'Ponedjeljak' WHEN 2 THEN N'Utorak' WHEN 3 THEN N'Srijeda'
            WHEN 4 THEN N'Četvrtak' WHEN 5 THEN N'Petak' WHEN 6 THEN N'Subota'
            WHEN 7 THEN N'Nedjelja'
        END,
        CONVERT(bit, CASE WHEN (DATEDIFF(day, CONVERT(date, '19000101', 112), DateValue) % 7) + 1 IN (6, 7) THEN 1 ELSE 0 END),
        NULL
    FROM Calendar
    OPTION (MAXRECURSION 0);

    IF (SELECT COUNT(*) FROM [bi].[DimSpace]) <> (SELECT COUNT(*) FROM [stg].[Space])
    BEGIN
        THROW 51001, N'Not every staging space was transferred to bi.DimSpace.', 1;
    END;

    ;WITH ReservationSegments AS
    (
        SELECT
            r.ReservationCode,
            r.SpaceCode,
            r.BookingStatus,
            r.EndDateTime AS ReservationEnd,
            CONVERT(datetime2(0), r.StartDateTime) AS SegmentStart,
            CONVERT(datetime2(0), CASE
                WHEN DATEADD(hour, DATEDIFF(hour, 0, r.StartDateTime) + 1, 0) < r.EndDateTime
                    THEN DATEADD(hour, DATEDIFF(hour, 0, r.StartDateTime) + 1, 0)
                ELSE r.EndDateTime
            END) AS SegmentEnd
        FROM [stg].[Reservation] AS r

        UNION ALL

        SELECT
            s.ReservationCode,
            s.SpaceCode,
            s.BookingStatus,
            s.ReservationEnd,
            CONVERT(datetime2(0), s.SegmentEnd) AS SegmentStart,
            CONVERT(datetime2(0), CASE
                WHEN DATEADD(hour, DATEDIFF(hour, 0, s.SegmentEnd) + 1, 0) < s.ReservationEnd
                    THEN DATEADD(hour, DATEDIFF(hour, 0, s.SegmentEnd) + 1, 0)
                ELSE s.ReservationEnd
            END) AS SegmentEnd
        FROM ReservationSegments AS s
        WHERE s.SegmentEnd < s.ReservationEnd
    )
    INSERT INTO [bi].[FactReservationHour]
    (
        ReservationCode, SpaceKey, DateKey, HourKey, StatusKey,
        SegmentStart, SegmentEnd, ReservedHours
    )
    SELECT
        s.ReservationCode,
        dspace.SpaceKey,
        ddate.DateKey,
        CONVERT(tinyint, DATEPART(hour, s.SegmentStart)),
        dstatus.StatusKey,
        s.SegmentStart,
        s.SegmentEnd,
        CONVERT(decimal(6,4), DATEDIFF(second, s.SegmentStart, s.SegmentEnd) / 3600.0)
    FROM ReservationSegments AS s
    INNER JOIN [bi].[DimSpace] AS dspace ON dspace.SpaceCode = s.SpaceCode
    INNER JOIN [bi].[DimDate] AS ddate ON ddate.DateValue = CONVERT(date, s.SegmentStart)
    INNER JOIN [bi].[DimBookingStatus] AS dstatus ON dstatus.StatusName = s.BookingStatus
    OPTION (MAXRECURSION 0);

    COMMIT TRANSACTION;
    PRINT N'MeetSpaceBI dimensional model was populated successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT 'DimSpace' AS TableName, COUNT(*) AS RowsInTable FROM [bi].[DimSpace]
UNION ALL SELECT 'DimDate', COUNT(*) FROM [bi].[DimDate]
UNION ALL SELECT 'DimHour', COUNT(*) FROM [bi].[DimHour]
UNION ALL SELECT 'DimBookingStatus', COUNT(*) FROM [bi].[DimBookingStatus]
UNION ALL SELECT 'FactReservationHour', COUNT(*) FROM [bi].[FactReservationHour];
GO
