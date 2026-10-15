#!/usr/bin/env python3
import argparse
import json
import plistlib
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

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
catalog_builder = Path("scripts/build-content-catalog.py")

for path in [
    project,
    privacy_manifest,
    launch_config,
    version_file,
    icon,
    shipping_validator,
    catalog_builder,
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

main_target_match = re.search(
    r"(?ms)^  ParkHunt:\n(?P<body>.*?)(?=^  ParkHuntClip:\n)",
    project_text,
)
if not main_target_match:
    errors.append("project.yml: ParkHunt target definition is missing")
else:
    main_target_body = main_target_match.group("body")
    if not re.search(
        r"(?m)^      - path: ParkHunt\s*$",
        main_target_body,
    ):
        errors.append(
            "project.yml: ParkHunt target must include the ParkHunt source root so PrivacyInfo.xcprivacy is bundled"
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

    required_url_keys = {
        "supportURL",
        "privacyPolicyURL",
    }
    required_boolean_keys = {
        "appStoreConnectAppRecordCreated",
        "appleDeveloperBundleIDRegistered",
        "appClipExperienceConfigured",
        "agreementsAccepted",
        "screenshotsPrepared",
        "ageRatingCompleted",
        "exportComplianceCompleted",
        "appReviewContactConfigured",
        "pricingAndAvailabilityConfigured",
    }
    required_external_keys = required_url_keys | required_boolean_keys

    missing_external_keys = required_external_keys - set(external)
    for key in sorted(missing_external_keys):
        errors.append(
            f"AppStore/launch-config.json: missing external requirement '{key}'"
        )

    unexpected_external_keys = set(external) - required_external_keys
    for key in sorted(unexpected_external_keys):
        errors.append(
            f"AppStore/launch-config.json: unknown external requirement '{key}'"
        )

    for key in sorted(required_url_keys & set(external)):
        value = external[key]
        if value is None or value == "":
            blockers.append(f"external requirement unresolved: {key}")
            continue
        if not isinstance(value, str):
            errors.append(
                f"AppStore/launch-config.json: {key} must be a URL string or null"
            )
            continue
        parsed = urlparse(value)
        if parsed.scheme != "https" or not parsed.netloc:
            errors.append(
                f"AppStore/launch-config.json: {key} must be an absolute https URL"
            )

    for key in sorted(required_boolean_keys & set(external)):
        value = external[key]
        if not isinstance(value, bool):
            errors.append(
                f"AppStore/launch-config.json: {key} must be boolean"
            )
        elif value is False:
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

    catalog_result = subprocess.run(
        [sys.executable, str(catalog_builder), "--check"],
        text=True,
        capture_output=True,
    )
    if catalog_result.returncode != 0:
        blockers.append(
            "generated runtime catalog is stale; regenerate ParkHunt/Resources/content-catalog.json before submission"
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
