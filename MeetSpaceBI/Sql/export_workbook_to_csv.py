"""Export the six data sheets from the prepared workbook to UTF-8 CSV.

Uses only Python's standard library, so the export does not depend on the
Microsoft ACE OLE DB provider required by the SSMS Excel import wizard.
"""

from __future__ import annotations

import csv
import re
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKBOOK = ROOT / "outputs" / "meetspace-bi-20261114" / "MeetSpace_BI_podaci_v6_satni.xlsx"
OUTPUT = ROOT / "MeetSpaceBI" / "Data"
SHEETS = {
    "Gradovi": "City.csv",
    "Objekti": "Facility.csv",
    "Tipovi": "SpaceType.csv",
    "Prostori": "Space.csv",
    "Rezervacije": "Reservation.csv",
    "Izvori": "Source.csv",
}

MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
NS = {"m": MAIN_NS, "r": REL_NS}


def column_index(cell_reference: str) -> int:
    letters = re.match(r"[A-Z]+", cell_reference).group(0)
    number = 0
    for letter in letters:
        number = number * 26 + ord(letter) - ord("A") + 1
    return number - 1


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(WORKBOOK) as archive:
        workbook = ET.fromstring(archive.read("xl/workbook.xml"))
        relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
        targets = {
            item.attrib["Id"]: item.attrib["Target"]
            for item in relationships.findall(f"{{{PKG_REL_NS}}}Relationship")
        }
        sheet_paths = {}
        for sheet in workbook.find("m:sheets", NS):
            target = targets[sheet.attrib[f"{{{REL_NS}}}id"]].lstrip("/")
            if not target.startswith("xl/"):
                target = "xl/" + target
            sheet_paths[sheet.attrib["name"]] = target

        shared_strings = []
        if "xl/sharedStrings.xml" in archive.namelist():
            strings_root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            for item in strings_root.findall("m:si", NS):
                shared_strings.append("".join(node.text or "" for node in item.findall(".//m:t", NS)))

        for sheet_name, filename in SHEETS.items():
            root = ET.fromstring(archive.read(sheet_paths[sheet_name]))
            rows = []
            max_columns = 0
            for row_element in root.findall("m:sheetData/m:row", NS):
                row = []
                for cell in row_element.findall("m:c", NS):
                    index = column_index(cell.attrib["r"])
                    while len(row) <= index:
                        row.append("")
                    value_node = cell.find("m:v", NS)
                    value = "" if value_node is None or value_node.text is None else value_node.text
                    cell_type = cell.attrib.get("t")
                    if cell_type == "s" and value:
                        value = shared_strings[int(value)]
                    elif cell_type == "inlineStr":
                        value = "".join(node.text or "" for node in cell.findall(".//m:t", NS))
                    row[index] = value
                if any(value != "" for value in row):
                    rows.append(row)
                    max_columns = max(max_columns, len(row))

            output_path = OUTPUT / filename
            with output_path.open("w", encoding="utf-8-sig", newline="") as output_file:
                writer = csv.writer(output_file, lineterminator="\n")
                for row in rows:
                    writer.writerow(row + [""] * (max_columns - len(row)))
            print(f"{sheet_name}: {len(rows) - 1} data rows -> {output_path}")


if __name__ == "__main__":
    main()
