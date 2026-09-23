#!/usr/bin/env python3
import re
import sys
from pathlib import Path

ROOT = Path("ParkHunt")
errors = []

persistent_location_terms = [
    "LocationFix",
    "CLLocation",
    "latitude",
    "longitude",
    "horizontalAccuracyMeters",
    "coordinate",
]

for path in ROOT.rglob("*.swift"):
    text = path.read_text(encoding="utf-8")

    if "UserDefaults" in text:
        for term in persistent_location_terms:
            if term in text:
                errors.append(
                    f"{path}: UserDefaults persistence references precise-location term '{term}'"
                )

location_service = Path("ParkHunt/Core/Location/LocationService.swift")
if location_service.exists():
    text = location_service.read_text(encoding="utf-8")
    match = re.search(
        r"struct\s+LocationFix\s*:\s*([^\{]+)",
        text,
    )
    if match and "Codable" in match.group(1):
        errors.append(
            "LocationFix must remain non-Codable so foreground fixes cannot be serialized accidentally."
        )

analytics_schema = Path("ParkHunt/Core/Analytics/AnalyticsEvent.swift")
if analytics_schema.exists():
    text = analytics_schema.read_text(encoding="utf-8")
    banned_analytics_identifiers = [
        "LocationFix",
        "CLLocation",
        "latitude",
        "longitude",
        "horizontalAccuracyMeters",
        "revealDescription",
        "revealImageName",
        "thumbnailImageName",
        "title",
        "tags",
        "deviceID",
        "userID",
    ]

    for term in banned_analytics_identifiers:
        if term in text:
            errors.append(
                f"{analytics_schema}: analytics schema contains banned identifier '{term}'"
            )

location_dir = Path("ParkHunt/Core/Location")
for path in location_dir.rglob("*.swift"):
    text = path.read_text(encoding="utf-8")
    for persistence_api in [
        "UserDefaults",
        "FileManager",
        "write(to:",
        "Data.write",
    ]:
        if persistence_api in text:
            errors.append(
                f"{path}: location layer contains persistence API '{persistence_api}'"
            )

if errors:
    print("Privacy boundary verification failed:")
    for error in errors:
        print(f"  - {error}")
    sys.exit(1)

print("Privacy boundary verification passed.")
