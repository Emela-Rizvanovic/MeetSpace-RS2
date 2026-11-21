"""Generate one transactional SQL load script from the UTF-8 CSV exports."""

from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "MeetSpaceBI" / "Data"
OUTPUT = ROOT / "MeetSpaceBI" / "Sql" / "02_load_staging_data.sql"
BATCH_SIZE = 500


TABLES = [
    ("City.csv", "stg.City", ["CityCode", "CityName", "CountryName"], {}),
    ("Facility.csv", "stg.Facility", ["FacilityCode", "FacilityName", "Address", "CityCode", "SourceCode", "DataOrigin"], {}),
    ("SpaceType.csv", "stg.SpaceType", ["SpaceTypeCode", "SpaceTypeName"], {}),
    ("Space.csv", "stg.Space", ["SpaceCode", "SpaceName", "SpaceTypeCode", "FacilityCode", "Capacity", "MeetSpaceSpaceId", "NameBasis", "SourceCode"], {"Capacity", "MeetSpaceSpaceId"}),
    ("Reservation.csv", "stg.Reservation", ["ReservationCode", "SpaceCode", "StartDateTime", "EndDateTime", "BookingStatus", "DataOrigin"], set()),
    ("Source.csv", "stg.Source", ["SourceCode", "SourceTitle", "URL", "DetailsUsed", "DateReviewed"], set()),
]


def sql_string(value: str) -> str:
    return "N'" + value.replace("'", "''") + "'"


def sql_value(column: str, value: str, numeric_columns: set[str]) -> str:
    if value == "":
        return "NULL"
    if column in numeric_columns:
        return value
    if column in {"StartDateTime", "EndDateTime"}:
        # The workbook stores these as ISO UTC-formatted values. The model uses
        # local booking wall-clock times in datetime2, so drop the Z marker.
        local_value = value.removesuffix("Z").removesuffix(".000")
        return f"CONVERT(datetime2(0), {sql_string(local_value)}, 126)"
    if column == "DateReviewed":
        return f"CONVERT(date, {sql_string(value)}, 23)"
    return sql_string(value)


def main() -> None:
    statements = [
        "/* Generated from MeetSpace_BI_podaci_v6_satni.xlsx. Synthetic records are loaded only into MeetSpaceBI staging. */",
        "USE [MeetSpaceBI];",
        "GO",
        "SET NOCOUNT ON;",
        "SET XACT_ABORT ON;",
        "IF EXISTS (SELECT 1 FROM [stg].[City]) OR EXISTS (SELECT 1 FROM [stg].[Facility]) OR EXISTS (SELECT 1 FROM [stg].[SpaceType]) OR EXISTS (SELECT 1 FROM [stg].[Space]) OR EXISTS (SELECT 1 FROM [stg].[Reservation]) OR EXISTS (SELECT 1 FROM [stg].[Source])",
        "BEGIN",
        "    RAISERROR(N'Staging tables are not empty. No rows were loaded to prevent duplicates; inspect the tables before continuing.', 16, 1);",
        "    RETURN;",
        "END;",
        "BEGIN TRY",
        "    BEGIN TRANSACTION;",
    ]

    for filename, table, columns, numeric_columns in TABLES:
        with (DATA / filename).open("r", encoding="utf-8-sig", newline="") as source:
            reader = csv.DictReader(source)
            rows = list(reader)
        col_list = ", ".join(f"[{column}]" for column in columns)
        for offset in range(0, len(rows), BATCH_SIZE):
            batch = rows[offset : offset + BATCH_SIZE]
            statements.append(f"    INSERT INTO [{table.replace('.', '].[')}] ({col_list}) VALUES")
            values_lines = []
            for row in batch:
                values = ", ".join(sql_value(column, row.get(column, ""), numeric_columns) for column in columns)
                values_lines.append(f"        ({values})")
            statements.append(",\n".join(values_lines) + ";")

    statements.extend(
        [
            "    COMMIT TRANSACTION;",
            "    PRINT N'Loaded staging data successfully.';",
            "END TRY",
            "BEGIN CATCH",
            "    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;",
            "    THROW;",
            "END CATCH;",
            "GO",
        ]
    )
    OUTPUT.write_text("\n".join(statements) + "\n", encoding="utf-8-sig")
    print(f"Created {OUTPUT} ({OUTPUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
