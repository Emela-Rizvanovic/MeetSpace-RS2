/* Optional rollback: restores original timestamps from the backup made by script 04. */
USE [MeetSpaceBI];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF OBJECT_ID(N'stg.Reservation_HourAlignmentBackup', N'U') IS NULL
    THROW 51100, N'No alignment backup exists; no changes were made.', 1;
IF (SELECT COUNT(*) FROM [stg].[Reservation_HourAlignmentBackup]) <> 5000
    THROW 51101, N'The alignment backup is incomplete; no changes were made.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    DELETE FROM [bi].[FactReservationHour];
    UPDATE target
    SET StartDateTime = source.StartDateTime, EndDateTime = source.EndDateTime
    FROM [stg].[Reservation] AS target
    INNER JOIN [stg].[Reservation_HourAlignmentBackup] AS source
        ON source.ReservationCode = target.ReservationCode;
    ;WITH ReservationSegments AS
    (
        SELECT r.ReservationCode, r.SpaceCode, r.BookingStatus, r.EndDateTime AS ReservationEnd,
               CONVERT(datetime2(0), r.StartDateTime) AS SegmentStart,
               CONVERT(datetime2(0), CASE
                   WHEN DATEADD(hour, DATEDIFF(hour, 0, r.StartDateTime) + 1, 0) < r.EndDateTime
                       THEN DATEADD(hour, DATEDIFF(hour, 0, r.StartDateTime) + 1, 0)
                   ELSE r.EndDateTime END) AS SegmentEnd
        FROM [stg].[Reservation] AS r
        UNION ALL
        SELECT s.ReservationCode, s.SpaceCode, s.BookingStatus, s.ReservationEnd,
               CONVERT(datetime2(0), s.SegmentEnd),
               CONVERT(datetime2(0), CASE
                   WHEN DATEADD(hour, DATEDIFF(hour, 0, s.SegmentEnd) + 1, 0) < s.ReservationEnd
                       THEN DATEADD(hour, DATEDIFF(hour, 0, s.SegmentEnd) + 1, 0)
                   ELSE s.ReservationEnd END)
        FROM ReservationSegments AS s
        WHERE s.SegmentEnd < s.ReservationEnd
    )
    INSERT INTO [bi].[FactReservationHour]
        (ReservationCode, SpaceKey, DateKey, HourKey, StatusKey, SegmentStart, SegmentEnd, ReservedHours)
    SELECT s.ReservationCode, dspace.SpaceKey, ddate.DateKey, CONVERT(tinyint, DATEPART(hour, s.SegmentStart)),
           dstatus.StatusKey, s.SegmentStart, s.SegmentEnd,
           CONVERT(decimal(6,4), DATEDIFF(second, s.SegmentStart, s.SegmentEnd) / 3600.0)
    FROM ReservationSegments AS s
    INNER JOIN [bi].[DimSpace] AS dspace ON dspace.SpaceCode = s.SpaceCode
    INNER JOIN [bi].[DimDate] AS ddate ON ddate.DateValue = CONVERT(date, s.SegmentStart)
    INNER JOIN [bi].[DimBookingStatus] AS dstatus ON dstatus.StatusName = s.BookingStatus
    OPTION (MAXRECURSION 0);
    IF (SELECT COUNT(*) FROM [bi].[FactReservationHour]) <> 13015
        THROW 51004, N'Unexpected fact row count after the hourly rebuild.', 1;
    COMMIT TRANSACTION;
    DROP TABLE [stg].[Reservation_HourAlignmentBackup];
    PRINT N'Original reservation times and the original hourly facts were restored.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
