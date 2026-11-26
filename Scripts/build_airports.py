#!/usr/bin/env python3
"""Build Resources/Data/Islam/Airports.tsv, the airport list Flight Mode picks From and To out of.

    ./Scripts/build_airports.py <airports.csv> [--tz-python <python with timezonefinder>]

The source is OurAirports' airports.csv (https://ourairports.com/data/, released into the public
domain). Kept: every airport with an IATA code and scheduled service (about 4,000 of 86,000), the
ones a passenger can hold a ticket to. One row each, tab separated, large airports first so a search
lists them first:

    IATA  size(L/M/S)  name  city  country(ISO 3166-1)  latitude  longitude  time zone  keywords

The time zone is what lets the form take the times printed on a boarding pass ("departs 10:35 PM
New York time, arrives 10:20 AM London time") instead of asking for a flight time. OurAirports does
not carry it, so it is looked up from the coordinates with `timezonefinder` (pip, not a dependency
of the app or of any other script: pass the interpreter of a virtualenv that has it). The keywords
are OurAirports' own alternate names ("Tokyo" for Narita), searched but never shown.

Compress afterwards, like every shipped data file: ./Scripts/compress_shipped.py --codec lzfse
Resources/Data/Islam/Airports.tsv (the app unpacks it only when the airport picker opens).
"""
import csv
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "Resources", "Data", "Islam", "Airports.tsv")
SIZES = {"large_airport": "L", "medium_airport": "M", "small_airport": "S"}

TZ_HELPER = r"""
import sys
from timezonefinder import TimezoneFinder
finder = TimezoneFinder()
for line in sys.stdin:
    lat, lon = line.split()
    print(finder.timezone_at(lat=float(lat), lng=float(lon)) or "")
"""


def clean(text):
    return " ".join(text.replace("\t", " ").split())


def main():
    args = sys.argv[1:]
    tz_python = sys.executable
    if "--tz-python" in args:
        at = args.index("--tz-python")
        tz_python = args[at + 1]
        del args[at:at + 2]
    if len(args) != 1:
        sys.exit(__doc__)

    rows = []
    with open(args[0], newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            if row["type"] not in SIZES or not row["iata_code"] or row["scheduled_service"] != "yes":
                continue
            rows.append(row)
    rank = {"L": 0, "M": 1, "S": 2}
    rows.sort(key=lambda r: (rank[SIZES[r["type"]]], r["iata_code"]))

    coordinates = "\n".join(f'{r["latitude_deg"]} {r["longitude_deg"]}' for r in rows) + "\n"
    zones = subprocess.run([tz_python, "-c", TZ_HELPER], input=coordinates, capture_output=True,
                           text=True, check=True).stdout.split("\n")[:len(rows)]
    missing = [r["iata_code"] for r, zone in zip(rows, zones) if not zone]
    if missing:
        sys.exit(f"no time zone for: {' '.join(missing)}")

    seen = set()
    lines = []
    for row, zone in zip(rows, zones):
        code = row["iata_code"].strip().upper()
        if len(code) != 3 or code in seen:
            continue
        seen.add(code)
        name, city = clean(row["name"]), clean(row["municipality"])
        # Alternate names only: what the name and the city already say would never be the match.
        shown = (name + " " + city).lower()
        keywords = ", ".join(word for word in (clean(k) for k in row["keywords"].split(","))
                             if word and word.lower() not in shown)[:80]
        lines.append("\t".join([
            code, SIZES[row["type"]], name, city, row["iso_country"].strip(),
            f'{float(row["latitude_deg"]):.4f}', f'{float(row["longitude_deg"]):.4f}', zone, keywords,
        ]))

    with open(OUT, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")
    print(f"{len(lines)} airports -> {os.path.relpath(OUT, REPO)} ({os.path.getsize(OUT) / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
