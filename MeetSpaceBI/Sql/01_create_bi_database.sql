/*
  MeetSpace diploma BI database
  Creates an isolated analytics database. Does not alter the operational
  MeetSpace database and does not insert synthetic reservation rows.
  Safe to run again: existing database objects are retained.
*/

USE [master];
GO

IF DB_ID(N'MeetSpaceBI') IS NULL
BEGIN
    CREATE DATABASE [MeetSpaceBI];
END;
GO

USE [MeetSpaceBI];
GO

IF SCHEMA_ID(N'stg') IS NULL EXEC(N'CREATE SCHEMA [stg]');
IF SCHEMA_ID(N'bi') IS NULL EXEC(N'CREATE SCHEMA [bi]');
GO

/* Staging tables mirror the prepared Excel workbook. */
IF OBJECT_ID(N'stg.City', N'U') IS NULL
BEGIN
    CREATE TABLE [stg].[City]
    (
        CityCode       varchar(20)   NOT NULL CONSTRAINT PK_stg_City PRIMARY KEY,
        CityName       nvarchar(100) NOT NULL,
        CountryName    nvarchar(100) NOT NULL
    );
END;
GO

IF OBJECT_ID(N'stg.Facility', N'U') IS NULL
BEGIN
    CREATE TABLE [stg].[Facility]
    (
        FacilityCode   varchar(30)    NOT NULL CONSTRAINT PK_stg_Facility PRIMARY KEY,
        FacilityName   nvarchar(200)  NOT NULL,
        Address        nvarchar(300)  NULL,
        CityCode       varchar(20)    NOT NULL,
        SourceCode     varchar(40)    NOT NULL,
        DataOrigin     nvarchar(100)  NOT NULL,
        CONSTRAINT FK_stg_Facility_City FOREIGN KEY (CityCode) REFERENCES [stg].[City](CityCode)
    );
END;
GO

IF OBJECT_ID(N'stg.SpaceType', N'U') IS NULL
BEGIN
    CREATE TABLE [stg].[SpaceType]
    (
        SpaceTypeCode  varchar(30)    NOT NULL CONSTRAINT PK_stg_SpaceType PRIMARY KEY,
        SpaceTypeName  nvarchar(150)  NOT NULL,
        Description    nvarchar(500)  NULL
    );
END;
GO

IF OBJECT_ID(N'stg.Space', N'U') IS NULL
BEGIN
    CREATE TABLE [stg].[Space]
    (
        SpaceCode          varchar(40)    NOT NULL CONSTRAINT PK_stg_Space PRIMARY KEY,
        SpaceName          nvarchar(200)  NOT NULL,
        SpaceTypeCode      varchar(30)    NOT NULL,
        FacilityCode       varchar(30)    NOT NULL,
        Capacity           int            NULL,
        MeetSpaceSpaceId   int            NULL,
        NameBasis          nvarchar(1000) NULL,
        SourceCode         varchar(40)    NOT NULL,
        CONSTRAINT FK_stg_Space_Facility FOREIGN KEY (FacilityCode) REFERENCES [stg].[Facility](FacilityCode),
        CONSTRAINT FK_stg_Space_Type FOREIGN KEY (SpaceTypeCode) REFERENCES [stg].[SpaceType](SpaceTypeCode),
        CONSTRAINT CK_stg_Space_Capacity CHECK (Capacity IS NULL OR Capacity > 0)
    );
END;
GO

IF OBJECT_ID(N'stg.Source', N'U') IS NULL
BEGIN
    CREATE TABLE [stg].[Source]
    (
        SourceCode       varchar(40)    NOT NULL CONSTRAINT PK_stg_Source PRIMARY KEY,
        SourceTitle      nvarchar(300)  NOT NULL,
        URL              nvarchar(1000) NULL,
        DetailsUsed      nvarchar(1500) NULL,
        DateReviewed     date           NULL
    );
END;
GO

IF OBJECT_ID(N'stg.Reservation', N'U') IS NULL
BEGIN
    CREATE TABLE [stg].[Reservation]
    (
        ReservationCode  varchar(40)   NOT NULL CONSTRAINT PK_stg_Reservation PRIMARY KEY,
        SpaceCode        varchar(40)   NOT NULL,
        StartDateTime    datetime2(0)  NOT NULL,
        EndDateTime      datetime2(0)  NOT NULL,
        BookingStatus    varchar(20)   NOT NULL,
        DataOrigin       nvarchar(1000) NULL,
        CONSTRAINT FK_stg_Reservation_Space FOREIGN KEY (SpaceCode) REFERENCES [stg].[Space](SpaceCode),
        CONSTRAINT CK_stg_Reservation_Interval CHECK (EndDateTime > StartDateTime),
        CONSTRAINT CK_stg_Reservation_Status CHECK (BookingStatus IN ('Approved', 'Pending', 'Rejected', 'Cancelled'))
    );
END;
GO

/* BI dimensions. Space attributes are flattened to make report filtering simple. */
IF OBJECT_ID(N'bi.DimSpace', N'U') IS NULL
BEGIN
    CREATE TABLE [bi].[DimSpace]
    (
        SpaceKey           int IDENTITY(1,1) NOT NULL CONSTRAINT PK_bi_DimSpace PRIMARY KEY,
        SpaceCode          varchar(40)    NOT NULL,
        SpaceName          nvarchar(200)  NOT NULL,
        FacilityCode       varchar(30)    NOT NULL,
        FacilityName       nvarchar(200)  NOT NULL,
        Address            nvarchar(300)  NULL,
        CityCode           varchar(20)    NOT NULL,
        CityName           nvarchar(100)  NOT NULL,
        SpaceTypeCode      varchar(30)    NOT NULL,
        SpaceTypeName      nvarchar(150)  NOT NULL,
        Capacity           int            NULL,
        MeetSpaceSpaceId   int            NULL,
        CONSTRAINT UQ_bi_DimSpace_SpaceCode UNIQUE (SpaceCode)
    );
END;
GO

IF OBJECT_ID(N'bi.DimDate', N'U') IS NULL
BEGIN
    CREATE TABLE [bi].[DimDate]
    (
        DateKey             int           NOT NULL CONSTRAINT PK_bi_DimDate PRIMARY KEY,
        DateValue           date          NOT NULL CONSTRAINT UQ_bi_DimDate_DateValue UNIQUE,
        CalendarYear        smallint      NOT NULL,
        MonthNumber         tinyint       NOT NULL,
        MonthName           nvarchar(20)  NOT NULL,
        DayOfMonth          tinyint       NOT NULL,
        DayOfWeekNumber     tinyint       NOT NULL,
        DayOfWeekName       nvarchar(20)  NOT NULL,
        IsWeekend           bit           NOT NULL,
        AcademicPeriodLabel nvarchar(100) NULL
    );
END;
GO

IF OBJECT_ID(N'bi.DimHour', N'U') IS NULL
BEGIN
    CREATE TABLE [bi].[DimHour]
    (
        HourKey       tinyint      NOT NULL CONSTRAINT PK_bi_DimHour PRIMARY KEY,
        HourNumber    tinyint      NOT NULL CONSTRAINT UQ_bi_DimHour_HourNumber UNIQUE,
        HourLabel     char(5)      NOT NULL,
        CONSTRAINT CK_bi_DimHour_Range CHECK (HourNumber BETWEEN 0 AND 23)
    );
END;
GO

IF OBJECT_ID(N'bi.DimBookingStatus', N'U') IS NULL
BEGIN
    CREATE TABLE [bi].[DimBookingStatus]
    (
        StatusKey       tinyint      NOT NULL CONSTRAINT PK_bi_DimBookingStatus PRIMARY KEY,
        StatusName      varchar(20)  NOT NULL CONSTRAINT UQ_bi_DimBookingStatus_Name UNIQUE,
        IsConfirmed     bit          NOT NULL
    );
END;
GO

/* Fact grain: one reservation's portion within one calendar hour. */
IF OBJECT_ID(N'bi.FactReservationHour', N'U') IS NULL
BEGIN
    CREATE TABLE [bi].[FactReservationHour]
    (
        ReservationHourKey bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_bi_FactReservationHour PRIMARY KEY,
        ReservationCode    varchar(40)    NOT NULL,
        SpaceKey           int            NOT NULL,
        DateKey            int            NOT NULL,
        HourKey            tinyint        NOT NULL,
        StatusKey          tinyint        NOT NULL,
        SegmentStart       datetime2(0)   NOT NULL,
        SegmentEnd         datetime2(0)   NOT NULL,
        ReservedHours      decimal(6,4)   NOT NULL,
        CONSTRAINT UQ_bi_FactReservationHour_Grain UNIQUE (ReservationCode, DateKey, HourKey),
        CONSTRAINT FK_bi_FactReservationHour_Space FOREIGN KEY (SpaceKey) REFERENCES [bi].[DimSpace](SpaceKey),
        CONSTRAINT FK_bi_FactReservationHour_Date FOREIGN KEY (DateKey) REFERENCES [bi].[DimDate](DateKey),
        CONSTRAINT FK_bi_FactReservationHour_Hour FOREIGN KEY (HourKey) REFERENCES [bi].[DimHour](HourKey),
        CONSTRAINT FK_bi_FactReservationHour_Status FOREIGN KEY (StatusKey) REFERENCES [bi].[DimBookingStatus](StatusKey),
        CONSTRAINT CK_bi_FactReservationHour_Segment CHECK (SegmentEnd > SegmentStart),
        CONSTRAINT CK_bi_FactReservationHour_Hours CHECK (ReservedHours > 0 AND ReservedHours <= 1)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM [bi].[DimHour])
BEGIN
    ;WITH Hours AS
    (
        SELECT 0 AS HourNumber
        UNION ALL
        SELECT HourNumber + 1 FROM Hours WHERE HourNumber < 23
    )
    INSERT INTO [bi].[DimHour] (HourKey, HourNumber, HourLabel)
    SELECT CONVERT(tinyint, HourNumber), CONVERT(tinyint, HourNumber),
           RIGHT('0' + CONVERT(varchar(2), HourNumber), 2) + ':00'
    FROM Hours
    OPTION (MAXRECURSION 24);
END;
GO

IF NOT EXISTS (SELECT 1 FROM [bi].[DimBookingStatus])
BEGIN
    INSERT INTO [bi].[DimBookingStatus] (StatusKey, StatusName, IsConfirmed)
    VALUES (1, 'Approved', 1), (2, 'Pending', 0), (3, 'Rejected', 0), (4, 'Cancelled', 0);
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'bi.FactReservationHour')
      AND name = N'IX_FactReservationHour_SpaceDateHour'
)
BEGIN
    CREATE INDEX IX_FactReservationHour_SpaceDateHour
        ON [bi].[FactReservationHour] (SpaceKey, DateKey, HourKey);
END;
GO

PRINT N'MeetSpaceBI database and empty BI schema are ready.';
PRINT N'No operational MeetSpace data was changed and no reservations were loaded.';
GO
