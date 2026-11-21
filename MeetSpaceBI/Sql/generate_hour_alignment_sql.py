"""Create guarded SQL scripts to align and, if needed, restore synthetic BI reservation times."""

from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "MeetSpaceBI" / "Data"
SQL = ROOT / "MeetSpaceBI" / "Sql"
ALIGN_SCRIPT = SQL / "04_align_reservation_hours.sql"
RESTORE_SCRIPT = SQL / "05_restore_original_reservation_hours.sql"
BACKUP_TABLE = "[stg].[Reservation_HourAlignmentBackup]"
BATCH_SIZE = 500


def quoted(value: str) -> str:
    return "N'" + value.replace("'", "''") + "'"


def datetime_value(value: str) -> str:
    return f"CONVERT(datetime2(0), {quoted(value.removesuffix('.000Z').removesuffix('Z'))}, 126)"


def fact_rebuild_sql(expected_rows: int) -> list[str]:
    return [
        "    ;WITH ReservationSegments AS",
        "    (",
        "        SELECT r.ReservationCode, r.SpaceCode, r.BookingStatus, r.EndDateTime AS ReservationEnd,",
        "               CONVERT(datetime2(0), r.StartDateTime) AS SegmentStart,",
        "               CONVERT(datetime2(0), CASE",
        "                   WHEN DATEADD(hour, DATEDIFF(hour, 0, r.StartDateTime) + 1, 0) < r.EndDateTime",
        "                       THEN DATEADD(hour, DATEDIFF(hour, 0, r.StartDateTime) + 1, 0)",
        "                   ELSE r.EndDateTime END) AS SegmentEnd",
        "        FROM [stg].[Reservation] AS r",
        "        UNION ALL",
        "        SELECT s.ReservationCode, s.SpaceCode, s.BookingStatus, s.ReservationEnd,",
        "               CONVERT(datetime2(0), s.SegmentEnd),",
        "               CONVERT(datetime2(0), CASE",
        "                   WHEN DATEADD(hour, DATEDIFF(hour, 0, s.SegmentEnd) + 1, 0) < s.ReservationEnd",
        "                       THEN DATEADD(hour, DATEDIFF(hour, 0, s.SegmentEnd) + 1, 0)",
        "                   ELSE s.ReservationEnd END)",
        "        FROM ReservationSegments AS s",
        "        WHERE s.SegmentEnd < s.ReservationEnd",
        "    )",
        "    INSERT INTO [bi].[FactReservationHour]",
        "        (ReservationCode, SpaceKey, DateKey, HourKey, StatusKey, SegmentStart, SegmentEnd, ReservedHours)",
        "    SELECT s.ReservationCode, dspace.SpaceKey, ddate.DateKey, CONVERT(tinyint, DATEPART(hour, s.SegmentStart)),",
        "           dstatus.StatusKey, s.SegmentStart, s.SegmentEnd,",
        "           CONVERT(decimal(6,4), DATEDIFF(second, s.SegmentStart, s.SegmentEnd) / 3600.0)",
        "    FROM ReservationSegments AS s",
        "    INNER JOIN [bi].[DimSpace] AS dspace ON dspace.SpaceCode = s.SpaceCode",
        "    INNER JOIN [bi].[DimDate] AS ddate ON ddate.DateValue = CONVERT(date, s.SegmentStart)",
        "    INNER JOIN [bi].[DimBookingStatus] AS dstatus ON dstatus.StatusName = s.BookingStatus",
        "    OPTION (MAXRECURSION 0);",
        f"    IF (SELECT COUNT(*) FROM [bi].[FactReservationHour]) <> {expected_rows}",
        "        THROW 51004, N'Unexpected fact row count after the hourly rebuild.', 1;",
    ]


def generate_align(reservations: list[dict[str, str]], expected_rows: int) -> None:
    lines = [
        "/* One-time update: retains all reservations and backs up the previous synthetic timestamps. */",
        "USE [MeetSpaceBI];",
        "GO",
        "SET NOCOUNT ON;",
        "SET XACT_ABORT ON;",
        "IF DB_NAME() <> N'MeetSpaceBI' THROW 51000, N'Run this script only in MeetSpaceBI.', 1;",
        "IF OBJECT_ID(N'stg.Reservation_HourAlignmentBackup', N'U') IS NOT NULL",
        "    THROW 51001, N'The alignment backup already exists; no changes were made.', 1;",
        "IF (SELECT COUNT(*) FROM [stg].[Reservation]) <> 5000",
        "    THROW 51002, N'Expected 5,000 staged reservations; no changes were made.', 1;",
        "IF (SELECT COUNT(*) FROM [bi].[DimSpace]) <> 37",
        "    THROW 51003, N'Expected the 37-space BI catalog; no changes were made.', 1;",
        "IF (SELECT COUNT(*) FROM [bi].[FactReservationHour]) <> 13015",
        "    THROW 51005, N'Expected the original 13,015 hourly facts; no changes were made.', 1;",
        "BEGIN TRY",
        "    BEGIN TRANSACTION;",
        "    SELECT ReservationCode, SpaceCode, StartDateTime, EndDateTime, BookingStatus, DataOrigin",
        "    INTO [stg].[Reservation_HourAlignmentBackup]",
        "    FROM [stg].[Reservation];",
        "    DELETE FROM [bi].[FactReservationHour];",
    ]

    for offset in range(0, len(reservations), BATCH_SIZE):
        batch = reservations[offset : offset + BATCH_SIZE]
        lines.extend(
            [
                "    UPDATE target",
                "    SET StartDateTime = source.StartDateTime, EndDateTime = source.EndDateTime",
                "    FROM [stg].[Reservation] AS target",
                "    INNER JOIN (VALUES",
            ]
        )
        values = []
        for row in batch:
            values.append(
                "        (" + ", ".join(
                    [quoted(row["ReservationCode"]), datetime_value(row["StartDateTime"]), datetime_value(row["EndDateTime"])]
                ) + ")"
            )
        lines.append(",\n".join(values))
        lines.extend(
            [
                "    ) AS source(ReservationCode, StartDateTime, EndDateTime)",
                "        ON source.ReservationCode = target.ReservationCode;",
            ]
        )

    lines.extend(
        [
            "    IF EXISTS (SELECT 1 FROM [stg].[Reservation] WHERE",
            "        CONVERT(date, StartDateTime) <> CONVERT(date, EndDateTime)",
            "        OR CONVERT(time(0), StartDateTime) < '08:00'",
            "        OR CONVERT(time(0), EndDateTime) > '16:00'",
            "        OR DATEPART(minute, StartDateTime) <> 0 OR DATEPART(second, StartDateTime) <> 0",
            "        OR DATEPART(minute, EndDateTime) <> 0 OR DATEPART(second, EndDateTime) <> 0)",
            "        THROW 51006, N'Reservation times do not match the 08:00–16:00 whole-hour slots.', 1;",
            "    IF (SELECT COUNT(*) FROM [stg].[Reservation]) <> 5000",
            "        THROW 51007, N'The reservation count changed unexpectedly.', 1;",
        ]
    )
    lines.extend(fact_rebuild_sql(expected_rows))
    lines.extend(
        [
            "    COMMIT TRANSACTION;",
            "    PRINT N'All 5,000 reservations now use whole-hour slots from 08:00 through 16:00.';",
            "END TRY",
            "BEGIN CATCH",
            "    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;",
            "    THROW;",
            "END CATCH;",
            "GO",
            "SELECT COUNT(*) AS Reservations FROM [stg].[Reservation];",
            "SELECT COUNT(*) AS HourlyFactRows FROM [bi].[FactReservationHour];",
            "SELECT MIN(StartDateTime) AS FirstReservation, MAX(EndDateTime) AS LastReservation FROM [stg].[Reservation];",
            "GO",
        ]
    )
    ALIGN_SCRIPT.write_text("\n".join(lines) + "\n", encoding="utf-8-sig")


def generate_restore(expected_rows: int) -> None:
    lines = [
        "/* Optional rollback: restores original timestamps from the backup made by script 04. */",
        "USE [MeetSpaceBI];",
        "GO",
        "SET NOCOUNT ON;",
        "SET XACT_ABORT ON;",
        "IF OBJECT_ID(N'stg.Reservation_HourAlignmentBackup', N'U') IS NULL",
        "    THROW 51100, N'No alignment backup exists; no changes were made.', 1;",
        "IF (SELECT COUNT(*) FROM [stg].[Reservation_HourAlignmentBackup]) <> 5000",
        "    THROW 51101, N'The alignment backup is incomplete; no changes were made.', 1;",
        "BEGIN TRY",
        "    BEGIN TRANSACTION;",
        "    DELETE FROM [bi].[FactReservationHour];",
        "    UPDATE target",
        "    SET StartDateTime = source.StartDateTime, EndDateTime = source.EndDateTime",
        "    FROM [stg].[Reservation] AS target",
        "    INNER JOIN [stg].[Reservation_HourAlignmentBackup] AS source",
        "        ON source.ReservationCode = target.ReservationCode;",
    ]
    lines.extend(fact_rebuild_sql(expected_rows))
    lines.extend(
        [
            "    COMMIT TRANSACTION;",
            "    DROP TABLE [stg].[Reservation_HourAlignmentBackup];",
            "    PRINT N'Original reservation times and the original hourly facts were restored.';",
            "END TRY",
            "BEGIN CATCH",
            "    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;",
            "    THROW;",
            "END CATCH;",
            "GO",
        ]
    )
    RESTORE_SCRIPT.write_text("\n".join(lines) + "\n", encoding="utf-8-sig")


def main() -> None:
    with (DATA / "Reservation.csv").open("r", encoding="utf-8-sig", newline="") as source:
        reservations = list(csv.DictReader(source))
    if len(reservations) != 5000:
        raise ValueError(f"Expected 5,000 reservations; found {len(reservations)}.")

    expected_rows = sum(
        int((datetime_from(row["EndDateTime"]) - datetime_from(row["StartDateTime"])).total_seconds() / 3600)
        for row in reservations
    )
    generate_align(reservations, expected_rows)
    generate_restore(13015)
    print(f"Generated {ALIGN_SCRIPT} and {RESTORE_SCRIPT}; aligned fact rows: {expected_rows}")


def datetime_from(value: str):
    from datetime import datetime
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


if __name__ == "__main__":
    main()
