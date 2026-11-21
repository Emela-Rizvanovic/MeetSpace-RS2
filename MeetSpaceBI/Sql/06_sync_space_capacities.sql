/*
  Synchronize the 22 simulated capacities with the operational app catalog.
  This script changes BI space metadata only; it does not alter reservations,
  hourly facts, dimensions other than Capacity, or the operational database.
*/
USE [MeetSpaceBI];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @SimulatedCapacity TABLE
(
    SpaceCode varchar(40) NOT NULL PRIMARY KEY,
    Capacity int NOT NULL CHECK (Capacity > 0)
);

INSERT INTO @SimulatedCapacity (SpaceCode, Capacity) VALUES
    ('SP-MOS-CODE-OPEN', 12),
    ('SP-MOS-INTERA-CONF', 12),
    ('SP-MOS-INTERA-PRES', 18),
    ('SP-MOS-OLDTOWN-COWORK', 10),
    ('SP-SAR-MOTIFF-COWORK', 12),
    ('SP-SAR-SKRIPTA-IDEALAB', 30),
    ('SP-SAR-TERSHOUSE-COWORK', 40),
    ('SP-SAR-TERSHOUSE-AMPHI', 80),
    ('SP-SAR-MIKROHUB-COWORK', 10),
    ('SP-SAR-MIKROHUB-MEETING', 8),
    ('SP-BL-QUO-OPEN', 12),
    ('SP-BL-QUO-ZOOM', 2),
    ('SP-BL-QUO-CONF', 14),
    ('SP-BL-SPACE-WORK', 12),
    ('SP-BL-SPACE-CONF', 12),
    ('SP-BL-SPACE-SILENT1', 2),
    ('SP-BL-SPACE-SILENT2', 2),
    ('SP-BL-KODE-HOTDESK', 12),
    ('SP-BL-KODE-MEET1', 8),
    ('SP-BL-KODE-MEET2', 8),
    ('SP-BL-KODE-MEET3', 8),
    ('SP-BL-KODE-TUTORIAL', 16);

IF (SELECT COUNT(*) FROM @SimulatedCapacity) <> 22
   OR (SELECT COUNT(*) FROM [bi].[DimSpace]) <> 37
   OR (SELECT COUNT(*) FROM [stg].[Space]) <> 37
   OR (SELECT COUNT(*) FROM @SimulatedCapacity AS c
       INNER JOIN [bi].[DimSpace] AS s ON s.SpaceCode = c.SpaceCode) <> 22
   OR (SELECT COUNT(*) FROM @SimulatedCapacity AS c
       INNER JOIN [stg].[Space] AS s ON s.SpaceCode = c.SpaceCode) <> 22
BEGIN
    RAISERROR(N'Expected the complete 37-space BI model and staging catalog. No capacity changes were made.', 16, 1);
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE s
    SET Capacity = c.Capacity,
        NameBasis = CASE
            WHEN s.NameBasis LIKE N'%kapacitet simuliran za demonstracijsku aplikaciju%'
                THEN s.NameBasis
            ELSE CONCAT(COALESCE(NULLIF(s.NameBasis, N''), N'Kapacitet'),
                        N'; kapacitet simuliran za demonstracijsku aplikaciju')
        END
    FROM [stg].[Space] AS s
    INNER JOIN @SimulatedCapacity AS c ON c.SpaceCode = s.SpaceCode
    WHERE s.Capacity <> c.Capacity OR s.Capacity IS NULL
       OR s.NameBasis NOT LIKE N'%kapacitet simuliran za demonstracijsku aplikaciju%'
       OR s.NameBasis IS NULL;

    UPDATE s
    SET Capacity = c.Capacity
    FROM [bi].[DimSpace] AS s
    INNER JOIN @SimulatedCapacity AS c ON c.SpaceCode = s.SpaceCode
    WHERE s.Capacity <> c.Capacity OR s.Capacity IS NULL;

    COMMIT TRANSACTION;
    PRINT N'Simulated capacities synchronized for the BI space catalog. Reservation and fact rows were not changed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
