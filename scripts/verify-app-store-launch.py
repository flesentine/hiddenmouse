#!/usr/bin/env python3
import argparse
import json
import plistlib
import re
import sys
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument(
    "--strict",
    action="store_true",
    help="Fail on external App Store Connect/content blockers too.",
)
args = parser.parse_args()

errors = []
blockers = []

project = Path("project.yml")
privacy_manifest = Path("ParkHunt/PrivacyInfo.xcprivacy")
launch_config = Path("AppStore/launch-config.json")
version_file = Path("Config/Version.xcconfig")
icon = Path("ParkHunt/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
shipping_validator = Path("scripts/validate-content-admin.py")

for path in [
    project,
    privacy_manifest,
    launch_config,
    version_file,
    icon,
    shipping_validator,
]:
    if not path.exists():
        errors.append(f"{path}: missing")

def read(path):
    return path.read_text(encoding="utf-8") if path.exists() else ""

project_text = read(project)
version_text = read(version_file)

if privacy_manifest.exists():
    try:
        privacy = plistlib.loads(privacy_manifest.read_bytes())
    except Exception as exc:
        errors.append(f"{privacy_manifest}: invalid plist ({exc})")
    else:
        if privacy.get("NSPrivacyTracking") is not False:
            errors.append("PrivacyInfo.xcprivacy: tracking must remain false")
        if privacy.get("NSPrivacyCollectedDataTypes") != []:
            errors.append(
                "PrivacyInfo.xcprivacy: repo currently has no off-device data collection; collected-data list must stay empty unless implementation changes"
            )

        accessed = privacy.get("NSPrivacyAccessedAPITypes", [])
        user_defaults = [
            entry
            for entry in accessed
            if entry.get("NSPrivacyAccessedAPIType")
            == "NSPrivacyAccessedAPICategoryUserDefaults"
        ]
        if len(user_defaults) != 1:
            errors.append(
                "PrivacyInfo.xcprivacy: exactly one UserDefaults required-reason entry is required"
            )
        elif "CA92.1" not in user_defaults[0].get(
            "NSPrivacyAccessedAPITypeReasons", []
        ):
            errors.append(
                "PrivacyInfo.xcprivacy: app-local UserDefaults usage must declare CA92.1"
            )

if "path: ParkHunt" not in project_text:
    errors.append(
        "project.yml: ParkHunt source root must remain included so PrivacyInfo.xcprivacy is bundled"
    )

if launch_config.exists():
    try:
        config = json.loads(launch_config.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{launch_config}: invalid JSON ({exc})")
        config = {}
    app = config.get("app", {})
    listing = config.get("listing", {})
    privacy = config.get("privacy", {})
    external = config.get("externalRequirements", {})

    if app.get("bundleIdentifier") != "com.flesentine.parkhunt":
        errors.append(
            "AppStore/launch-config.json: bundle identifier must match production app"
        )
    if not app.get("independentAppDisclaimer"):
        errors.append(
            "AppStore/launch-config.json: independent-app disclaimer is required"
        )
    if not listing.get("subtitle"):
        errors.append("AppStore/launch-config.json: subtitle is required")
    if not listing.get("description"):
        errors.append("AppStore/launch-config.json: description is required")
    if privacy.get("tracking") is not False:
        errors.append("AppStore/launch-config.json: tracking must remain false")
    if privacy.get("dataSentOffDevice") is not False:
        errors.append(
            "AppStore/launch-config.json: current implementation must declare no off-device data transmission"
        )
    if privacy.get("userDefaultsRequiredReason") != "CA92.1":
        errors.append(
            "AppStore/launch-config.json: UserDefaults reason must match privacy manifest"
        )

    for key, value in external.items():
        if value in (None, False, ""):
            blockers.append(f"external requirement unresolved: {key}")

marketing = re.search(
    r"^MARKETING_VERSION\s*=\s*([^\s]+)\s*$",
    version_text,
    re.MULTILINE,
)
build = re.search(
    r"^CURRENT_PROJECT_VERSION\s*=\s*(\d+)\s*$",
    version_text,
    re.MULTILINE,
)
if not marketing:
    errors.append("Config/Version.xcconfig: MARKETING_VERSION missing")
elif args.strict and marketing.group(1).startswith("0."):
    blockers.append(
        "marketing version is still pre-release; set the intended public version before submission"
    )
if not build:
    errors.append("Config/Version.xcconfig: CURRENT_PROJECT_VERSION missing")

if not icon.exists():
    errors.append("1024px App Store icon is missing")

# Shipping content is intentionally checked in strict mode because the current
# field-test catalog may contain needsRecheck items while repo structure is valid.
if args.strict and shipping_validator.exists():
    import subprocess

    result = subprocess.run(
        [sys.executable, str(shipping_validator), "--shipping"],
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        blockers.append(
            "shipping content validation is not clean; field-test discoveries must be verified/removed before submission"
        )

if errors:
    print("App Store launch verification failed:")
    for error in errors:
        print(f"  - {error}")
    sys.exit(1)

print("App Store launch repository checks passed.")

if blockers:
    print("Launch blockers:")
    for blocker in blockers:
        print(f"  - {blocker}")

if args.strict and blockers:
    sys.exit(2)
