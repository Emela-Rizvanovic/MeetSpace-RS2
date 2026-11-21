SET NOCOUNT ON;

IF DB_ID(N'MeetSpaceBI') IS NULL
BEGIN
    SELECT 'EMPTY';
    RETURN;
END;

DECLARE @RequiredTables TABLE
(
    SchemaName sysname NOT NULL,
    TableName  sysname NOT NULL
);

INSERT INTO @RequiredTables (SchemaName, TableName) VALUES
    (N'stg', N'City'),
    (N'stg', N'Facility'),
    (N'stg', N'SpaceType'),
    (N'stg', N'Space'),
    (N'stg', N'Source'),
    (N'stg', N'Reservation'),
    (N'bi', N'DimSpace'),
    (N'bi', N'DimDate'),
    (N'bi', N'DimHour'),
    (N'bi', N'DimBookingStatus'),
    (N'bi', N'FactReservationHour');

DECLARE @RequiredTableCount int = (SELECT COUNT(*) FROM @RequiredTables);
DECLARE @PresentTableCount int =
(
    SELECT COUNT(*)
    FROM @RequiredTables AS required
    WHERE OBJECT_ID(QUOTENAME(N'MeetSpaceBI') + N'.' + QUOTENAME(required.SchemaName)
                    + N'.' + QUOTENAME(required.TableName), N'U') IS NOT NULL
);

IF @PresentTableCount = 0
BEGIN
    SELECT 'EMPTY';
    RETURN;
END;

IF @PresentTableCount <> @RequiredTableCount
BEGIN
    SELECT 'PARTIAL';
    RETURN;
END;

DECLARE @ReservationCount int;
DECLARE @CityCount int;
DECLARE @FacilityCount int;
DECLARE @SpaceTypeCount int;
DECLARE @StagingSpaceCount int;
DECLARE @SourceCount int;
DECLARE @SpaceCount int;
DECLARE @DateCount int;
DECLARE @HourCount int;
DECLARE @StatusCount int;
DECLARE @FactCount int;
DECLARE @NullCapacityCount int;
DECLARE @BadReservationCount int;
DECLARE @ReservationHours decimal(12, 2);
DECLARE @FactHours decimal(12, 2);
DECLARE @DistinctStatusCount int;
DECLARE @ApprovedCount int;
DECLARE @PendingCount int;
DECLARE @RejectedCount int;
DECLARE @CancelledCount int;
DECLARE @ApprovedHours decimal(12, 2);
DECLARE @FirstDate date;
DECLARE @LastDate date;

EXEC sys.sp_executesql
    N'SELECT @CityCount = COUNT(*) FROM [MeetSpaceBI].[stg].[City];
      SELECT @FacilityCount = COUNT(*) FROM [MeetSpaceBI].[stg].[Facility];
      SELECT @SpaceTypeCount = COUNT(*) FROM [MeetSpaceBI].[stg].[SpaceType];
      SELECT @StagingSpaceCount = COUNT(*) FROM [MeetSpaceBI].[stg].[Space];
      SELECT @SourceCount = COUNT(*) FROM [MeetSpaceBI].[stg].[Source];
      SELECT @ReservationCount = COUNT(*) FROM [MeetSpaceBI].[stg].[Reservation];
      SELECT @SpaceCount = COUNT(*) FROM [MeetSpaceBI].[bi].[DimSpace];
      SELECT @DateCount = COUNT(*) FROM [MeetSpaceBI].[bi].[DimDate];
      SELECT @FirstDate = MIN(DateValue), @LastDate = MAX(DateValue)
      FROM [MeetSpaceBI].[bi].[DimDate];
      SELECT @HourCount = COUNT(*) FROM [MeetSpaceBI].[bi].[DimHour];
      SELECT @StatusCount = COUNT(*) FROM [MeetSpaceBI].[bi].[DimBookingStatus];
      SELECT @FactCount = COUNT(*) FROM [MeetSpaceBI].[bi].[FactReservationHour];
      SELECT @NullCapacityCount =
          (SELECT COUNT(*) FROM [MeetSpaceBI].[stg].[Space] WHERE Capacity IS NULL OR Capacity <= 0)
        + (SELECT COUNT(*) FROM [MeetSpaceBI].[bi].[DimSpace] WHERE Capacity IS NULL OR Capacity <= 0);
      SELECT @BadReservationCount = COUNT(*)
      FROM [MeetSpaceBI].[stg].[Reservation]
      WHERE StartDateTime >= EndDateTime
         OR CONVERT(date, StartDateTime) <> CONVERT(date, EndDateTime)
         OR YEAR(StartDateTime) <> 2025
         OR DATEPART(minute, StartDateTime) <> 0 OR DATEPART(second, StartDateTime) <> 0
         OR DATEPART(minute, EndDateTime) <> 0 OR DATEPART(second, EndDateTime) <> 0
         OR DATEPART(hour, StartDateTime) < 8 OR DATEPART(hour, StartDateTime) >= 16
         OR DATEPART(hour, EndDateTime) > 16;
      SELECT @ReservationHours = COALESCE(SUM(DATEDIFF(second, StartDateTime, EndDateTime) / 3600.0), 0)
      FROM [MeetSpaceBI].[stg].[Reservation];
      SELECT @FactHours = COALESCE(SUM(ReservedHours), 0)
      FROM [MeetSpaceBI].[bi].[FactReservationHour];
      SELECT @DistinctStatusCount = COUNT(DISTINCT BookingStatus)
      FROM [MeetSpaceBI].[stg].[Reservation];
      SELECT
          @ApprovedCount = SUM(CASE WHEN BookingStatus = ''Approved'' THEN 1 ELSE 0 END),
          @PendingCount = SUM(CASE WHEN BookingStatus = ''Pending'' THEN 1 ELSE 0 END),
          @RejectedCount = SUM(CASE WHEN BookingStatus = ''Rejected'' THEN 1 ELSE 0 END),
          @CancelledCount = SUM(CASE WHEN BookingStatus = ''Cancelled'' THEN 1 ELSE 0 END),
          @ApprovedHours = COALESCE(SUM(CASE WHEN BookingStatus = ''Approved''
              THEN DATEDIFF(second, StartDateTime, EndDateTime) / 3600.0 ELSE 0 END), 0)
      FROM [MeetSpaceBI].[stg].[Reservation];',
    N'@CityCount int OUTPUT, @FacilityCount int OUTPUT, @SpaceTypeCount int OUTPUT,
      @StagingSpaceCount int OUTPUT, @SourceCount int OUTPUT, @ReservationCount int OUTPUT,
      @SpaceCount int OUTPUT, @DateCount int OUTPUT, @HourCount int OUTPUT,
      @StatusCount int OUTPUT, @FactCount int OUTPUT, @NullCapacityCount int OUTPUT,
      @BadReservationCount int OUTPUT, @ReservationHours decimal(12, 2) OUTPUT,
      @FactHours decimal(12, 2) OUTPUT, @DistinctStatusCount int OUTPUT,
      @ApprovedCount int OUTPUT, @PendingCount int OUTPUT, @RejectedCount int OUTPUT,
      @CancelledCount int OUTPUT, @ApprovedHours decimal(12, 2) OUTPUT,
      @FirstDate date OUTPUT, @LastDate date OUTPUT',
    @CityCount = @CityCount OUTPUT,
    @FacilityCount = @FacilityCount OUTPUT,
    @SpaceTypeCount = @SpaceTypeCount OUTPUT,
    @StagingSpaceCount = @StagingSpaceCount OUTPUT,
    @SourceCount = @SourceCount OUTPUT,
    @ReservationCount = @ReservationCount OUTPUT,
    @SpaceCount = @SpaceCount OUTPUT,
    @DateCount = @DateCount OUTPUT,
    @HourCount = @HourCount OUTPUT,
    @StatusCount = @StatusCount OUTPUT,
    @FactCount = @FactCount OUTPUT,
    @NullCapacityCount = @NullCapacityCount OUTPUT,
    @BadReservationCount = @BadReservationCount OUTPUT,
    @ReservationHours = @ReservationHours OUTPUT,
    @FactHours = @FactHours OUTPUT,
    @DistinctStatusCount = @DistinctStatusCount OUTPUT,
    @ApprovedCount = @ApprovedCount OUTPUT,
    @PendingCount = @PendingCount OUTPUT,
    @RejectedCount = @RejectedCount OUTPUT,
    @CancelledCount = @CancelledCount OUTPUT,
    @ApprovedHours = @ApprovedHours OUTPUT,
    @FirstDate = @FirstDate OUTPUT,
    @LastDate = @LastDate OUTPUT;

IF @CityCount = 0 AND @FacilityCount = 0 AND @SpaceTypeCount = 0
   AND @StagingSpaceCount = 0 AND @SourceCount = 0 AND @ReservationCount = 0
   AND @SpaceCount = 0 AND @DateCount = 0 AND @FactCount = 0
    SELECT 'EMPTY';
ELSE IF @CityCount = 4 AND @FacilityCount = 12 AND @SpaceTypeCount = 4
    AND @StagingSpaceCount = 37 AND @SourceCount = 19 AND @ReservationCount = 5000
    AND @SpaceCount = 37 AND @DateCount = 365 AND @HourCount = 24
    AND @FirstDate = CONVERT(date, '20250101', 112)
    AND @LastDate = CONVERT(date, '20251231', 112)
    AND @StatusCount = 4 AND @FactCount = 12145
    AND @NullCapacityCount = 0 AND @BadReservationCount = 0
    AND @ReservationHours = 12145 AND @FactHours = 12145 AND @DistinctStatusCount = 4
    AND @ApprovedCount = 4000 AND @PendingCount = 400
    AND @RejectedCount = 300 AND @CancelledCount = 300
    AND @ApprovedHours = 9704
    AND NOT EXISTS
    (
        SELECT expected.StatusName, expected.IsConfirmed
        FROM (VALUES
            ('Approved', CONVERT(bit, 1)),
            ('Pending', CONVERT(bit, 0)),
            ('Rejected', CONVERT(bit, 0)),
            ('Cancelled', CONVERT(bit, 0))
        ) AS expected(StatusName, IsConfirmed)
        EXCEPT
        SELECT StatusName, IsConfirmed FROM [MeetSpaceBI].[bi].[DimBookingStatus]
    )
    AND NOT EXISTS
    (
        SELECT s.SpaceCode, s.SpaceName, s.SpaceTypeCode, s.FacilityCode,
               f.CityCode, s.Capacity
        FROM [MeetSpaceBI].[stg].[Space] AS s
        INNER JOIN [MeetSpaceBI].[stg].[Facility] AS f ON f.FacilityCode = s.FacilityCode
        EXCEPT
        SELECT s.SpaceCode, s.SpaceName, s.SpaceTypeCode, s.FacilityCode,
               s.CityCode, s.Capacity
        FROM [MeetSpaceBI].[bi].[DimSpace] AS s
    )
    SELECT 'READY';
ELSE
    SELECT 'PARTIAL';
