"""Align the simulated reservation workbook and CSV to MeetSpace's hourly booking slots."""

from __future__ import annotations

import csv
import json
import math
import xml.etree.ElementTree as ET
import zipfile
from datetime import datetime, timedelta
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_WORKBOOK = ROOT / "outputs" / "meetspace-bi-20261114" / "MeetSpace_BI_podaci_v5.xlsx"
ALIGNED_WORKBOOK = ROOT / "outputs" / "meetspace-bi-20261114" / "MeetSpace_BI_podaci_v6_satni.xlsx"
RESERVATION_CSV = ROOT / "MeetSpaceBI" / "Data" / "Reservation.csv"
EXPORTER = ROOT / "MeetSpaceBI" / "Sql" / "export_workbook_to_csv.py"
SUMMARY = ROOT / "MeetSpaceBI" / "Data" / "ReservationHourAlignmentSummary.json"

MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
NS = {"m": MAIN_NS, "r": REL_NS}


def parse_datetime(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def format_datetime(value: datetime) -> str:
    return value.strftime("%Y-%m-%dT%H:%M:%S.000Z")


def normalize_interval(start_text: str, end_text: str) -> tuple[str, str, int]:
    start = parse_datetime(start_text)
    end = parse_datetime(end_text)
    duration = (end - start).total_seconds() / 3600
    whole_hours = max(1, min(8, math.floor(duration + 0.5)))

    # Round a half-hour start forward, then keep the whole booking within 08:00–16:00.
    start_hour = math.floor((start.hour * 60 + start.minute) / 60 + 0.5)
    start_hour = max(8, min(start_hour, 16 - whole_hours))
    aligned_start = start.replace(hour=start_hour, minute=0, second=0, microsecond=0)
    aligned_end = aligned_start + timedelta(hours=whole_hours)
    return format_datetime(aligned_start), format_datetime(aligned_end), whole_hours


def reservation_sheet_path(archive: zipfile.ZipFile) -> str:
    workbook = ET.fromstring(archive.read("xl/workbook.xml"))
    relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
    targets = {
        item.attrib["Id"]: item.attrib["Target"]
        for item in relationships.findall(f"{{{PKG_REL_NS}}}Relationship")
    }
    for sheet in workbook.find("m:sheets", NS):
        if sheet.attrib["name"] == "Rezervacije":
            target = targets[sheet.attrib[f"{{{REL_NS}}}id"]].lstrip("/")
            return target if target.startswith("xl/") else f"xl/{target}"
    raise ValueError("The workbook does not contain the Rezervacije sheet.")


def update_workbook(rows: list[dict[str, str]]) -> None:
    ET.register_namespace("x", MAIN_NS)
    with zipfile.ZipFile(SOURCE_WORKBOOK, "r") as source:
        sheet_path = reservation_sheet_path(source)
        sheet = ET.fromstring(source.read(sheet_path))
        worksheet_rows = sheet.findall("m:sheetData/m:row", NS)
        if len(worksheet_rows) != len(rows) + 1:
            raise ValueError("Workbook row count does not match Reservation.csv.")

        for row_element, reservation in zip(worksheet_rows[1:], rows, strict=True):
            cells = {cell.attrib.get("r", ""): cell for cell in row_element.findall("m:c", NS)}
            row_number = row_element.attrib["r"]
            for column, field in (("C", "StartDateTime"), ("D", "EndDateTime")):
                cell = cells.get(f"{column}{row_number}")
                if cell is None:
                    raise ValueError(f"Missing {column}{row_number} in the Rezervacije sheet.")
                value = cell.find("m:v", NS)
                if value is None:
                    value = ET.SubElement(cell, f"{{{MAIN_NS}}}v")
                value.text = reservation[field]
                cell.set("t", "d")

        updated_sheet = ET.tostring(sheet, encoding="utf-8", xml_declaration=True)
        with zipfile.ZipFile(ALIGNED_WORKBOOK, "w", compression=zipfile.ZIP_DEFLATED) as output:
            for entry in source.infolist():
                output.writestr(entry, updated_sheet if entry.filename == sheet_path else source.read(entry.filename))


def main() -> None:
    with RESERVATION_CSV.open("r", encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        fieldnames = reader.fieldnames
        rows = list(reader)

    if len(rows) != 5000 or not fieldnames:
        raise ValueError(f"Expected 5,000 reservations; found {len(rows)}.")

    durations: list[int] = []
    for row in rows:
        row["StartDateTime"], row["EndDateTime"], hours = normalize_interval(
            row["StartDateTime"], row["EndDateTime"]
        )
        durations.append(hours)

    update_workbook(rows)
    with RESERVATION_CSV.open("w", encoding="utf-8-sig", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)

    exporter = EXPORTER.read_text(encoding="utf-8")
    exporter = exporter.replace(
        'WORKBOOK = ROOT / "MeetSpaceBI" / "Data" / "MeetSpace_BI_podaci_v5.xlsx"',
        'WORKBOOK = ROOT / "outputs" / "meetspace-bi-20261114" / "MeetSpace_BI_podaci_v6_satni.xlsx"',
    )
    EXPORTER.write_text(exporter, encoding="utf-8")

    summary = {
        "reservationCount": len(rows),
        "firstStartHour": 8,
        "lastEndHour": 16,
        "wholeHourDurations": True,
        "reservationsKeptOnOriginalStartDate": True,
        "factRowsExpected": sum(durations),
        "durationHoursTotal": sum(durations),
        "durationHourCounts": {str(hour): durations.count(hour) for hour in sorted(set(durations))},
    }
    SUMMARY.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Aligned {len(rows)} reservations; generated {ALIGNED_WORKBOOK}")
    print(f"Expected hourly fact rows after rebuild: {summary['factRowsExpected']}")


if __name__ == "__main__":
    main()
