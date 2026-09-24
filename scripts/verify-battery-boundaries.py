#!/usr/bin/env python3
import re
import sys
from pathlib import Path

ROOT = Path("ParkHunt")
LOCATION_SERVICE = ROOT / "Core" / "Location" / "LocationService.swift"
NEARBY_VIEW = ROOT / "Features" / "Nearby" / "NearbyPermissionView.swift"
PROJECT = Path("project.yml")

errors = []

banned_patterns = {
    r"\bstartUpdatingLocation\s*\(": "continuous GPS updates",
    r"\bstartMonitoringSignificantLocationChanges\s*\(": "significant-change background monitoring",
    r"\bstartMonitoringVisits\s*\(": "visit monitoring",
    r"\brequestAlwaysAuthorization\s*\(": "Always location authorization",
    r"allowsBackgroundLocationUpdates\s*=\s*true": "background location updates",
    r"pausesLocationUpdatesAutomatically\s*=\s*false": "disabling automatic location pausing",
    r"\bkCLLocationAccuracyBestForNavigation\b": "navigation-grade location accuracy",
    r"\bkCLLocationAccuracyBest\b": "best location accuracy",
    r"\bkCLLocationAccuracyNearestTenMeters\b": "10-meter location accuracy",
}

for path in ROOT.rglob("*.swift"):
    text = path.read_text(encoding="utf-8")
    for pattern, description in banned_patterns.items():
        if re.search(pattern, text):
            errors.append(f"{path}: battery boundary forbids {description}")

if not LOCATION_SERVICE.exists():
    errors.append(f"{LOCATION_SERVICE}: missing")
else:
    text = LOCATION_SERVICE.read_text(encoding="utf-8")

    required_fragments = [
        "manager.requestLocation()",
        "requestedAccuracy = kCLLocationAccuracyHundredMeters",
        "LocationRequestPolicy.shouldRequest",
    ]
    for fragment in required_fragments:
        if fragment not in text:
            errors.append(
                f"{LOCATION_SERVICE}: missing required one-shot battery safeguard '{fragment}'"
            )

    request_count = text.count("manager.requestLocation()")
    if request_count != 1:
        errors.append(
            f"{LOCATION_SERVICE}: expected exactly one one-shot requestLocation call, found {request_count}"
        )

    stop_count = text.count("stopUpdatingLocation()")
    if stop_count < 4:
        errors.append(
            f"{LOCATION_SERVICE}: expected stopUpdatingLocation on cancellation and terminal callbacks; found only {stop_count} calls"
        )

if not NEARBY_VIEW.exists():
    errors.append(f"{NEARBY_VIEW}: missing")
else:
    text = NEARBY_VIEW.read_text(encoding="utf-8")

    if ".onDisappear" not in text:
        errors.append(
            f"{NEARBY_VIEW}: Nearby must stop/discard location when the view disappears"
        )

    if "case .inactive, .background:" not in text:
        errors.append(
            f"{NEARBY_VIEW}: Nearby must handle inactive/background scene phases"
        )

    discard_count = text.count("locationService.discardCurrentLocation()")
    if discard_count < 2:
        errors.append(
            f"{NEARBY_VIEW}: expected location discard on background and view exit; found {discard_count}"
        )

if PROJECT.exists():
    project_text = PROJECT.read_text(encoding="utf-8")
    background_mode_match = re.search(
        r"UIBackgroundModes[^\n]*location|location[^\n]*UIBackgroundModes",
        project_text,
        flags=re.IGNORECASE,
    )
    if background_mode_match:
        errors.append(
            f"{PROJECT}: background location mode is forbidden for the prototype"
        )

if errors:
    print("Battery boundary verification failed:")
    for error in errors:
        print(f"  - {error}")
    sys.exit(1)

print("Battery boundary verification passed.")
