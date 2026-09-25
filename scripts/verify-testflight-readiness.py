#!/usr/bin/env python3
import plistlib
import re
import sys
from pathlib import Path

errors = []
warnings = []

project = Path("project.yml")
version = Path("Config/Version.xcconfig")
release = Path("Config/Release.xcconfig")
export_options = Path("Config/ExportOptions-TestFlight.plist")
archive_script = Path("scripts/build-testflight-archive.sh")

required = [project, version, release, export_options, archive_script]
for path in required:
    if not path.exists():
        errors.append(f"{path}: missing")

def read(path):
    return path.read_text(encoding="utf-8") if path.exists() else ""

project_text = read(project)
version_text = read(version)
release_text = read(release)
archive_text = read(archive_script)

bundle_match = re.search(r"PRODUCT_BUNDLE_IDENTIFIER:\s*([^\s]+)", project_text)
if not bundle_match:
    errors.append("project.yml: PRODUCT_BUNDLE_IDENTIFIER is missing")
else:
    bundle_id = bundle_match.group(1)
    if bundle_id in {"com.example.app", "com.yourcompany.app"}:
        errors.append(f"project.yml: placeholder bundle identifier '{bundle_id}' is not TestFlight-ready")

if "\\${" in archive_text:
    errors.append("scripts/build-testflight-archive.sh: shell parameter expansion is incorrectly escaped")

if 'MODE="${1:-signed}"' not in archive_text:
    errors.append("scripts/build-testflight-archive.sh: signed/CI mode parameter expansion is missing")

if "scripts/run-command-with-timeout.py" not in archive_text:
    errors.append("scripts/build-testflight-archive.sh: CI archive timeout guard is missing")

if "CODE_SIGN_STYLE: Automatic" not in project_text:
    errors.append("project.yml: app target must use automatic signing for the documented TestFlight path")

if "GENERATE_INFOPLIST_FILE: YES" not in project_text:
    errors.append("project.yml: generated Info.plist setting is required")

if "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription:" not in project_text:
    errors.append("project.yml: When In Use location usage description is missing")

if "NSLocationAlways" in project_text:
    errors.append("project.yml: Always-location usage strings are not allowed")

if "MARKETING_VERSION:" in project_text or "CURRENT_PROJECT_VERSION:" in project_text:
    errors.append("project.yml: version metadata must come from Config/Version.xcconfig")

marketing = re.search(r"^MARKETING_VERSION\s*=\s*([^\s]+)\s*$", version_text, re.MULTILINE)
build = re.search(r"^CURRENT_PROJECT_VERSION\s*=\s*(\d+)\s*$", version_text, re.MULTILINE)

if not marketing:
    errors.append("Config/Version.xcconfig: MARKETING_VERSION is missing")
elif not re.fullmatch(r"\d+\.\d+\.\d+", marketing.group(1)):
    errors.append("Config/Version.xcconfig: MARKETING_VERSION must use x.y.z semantic version format")

if not build:
    errors.append("Config/Version.xcconfig: CURRENT_PROJECT_VERSION must be a positive integer")
elif int(build.group(1)) < 1:
    errors.append("Config/Version.xcconfig: CURRENT_PROJECT_VERSION must be >= 1")

required_release_settings = [
    "PARKHUNT_ENVIRONMENT = production",
    "PARKHUNT_PRODUCTION",
    "SWIFT_COMPILATION_MODE = wholemodule",
    "DEBUG_INFORMATION_FORMAT = dwarf-with-dsym",
    "VALIDATE_PRODUCT = YES",
]
for setting in required_release_settings:
    if setting not in release_text:
        errors.append(f"Config/Release.xcconfig: missing '{setting}'")

if export_options.exists():
    try:
        data = plistlib.loads(export_options.read_bytes())
    except Exception as exc:
        errors.append(f"{export_options}: invalid plist ({exc})")
    else:
        if data.get("method") != "app-store-connect":
            errors.append(f"{export_options}: method must be app-store-connect")
        if data.get("signingStyle") != "automatic":
            errors.append(f"{export_options}: signingStyle must be automatic")
        if data.get("manageAppVersionAndBuildNumber") is not False:
            errors.append(
                f"{export_options}: manageAppVersionAndBuildNumber must remain false so repository build metadata is authoritative"
            )
        if data.get("uploadSymbols") is not True:
            errors.append(f"{export_options}: uploadSymbols must be true")

assets = list(Path("ParkHunt").rglob("*.xcassets"))
if not assets:
    warnings.append(
        "No asset catalog is committed yet. A production App Store/TestFlight validation may require an AppIcon before upload."
    )

if errors:
    print("TestFlight readiness verification failed:")
    for error in errors:
        print(f"  - {error}")
    for warning in warnings:
        print(f"  warning: {warning}")
    sys.exit(1)

print("TestFlight readiness verification passed.")
for warning in warnings:
    print(f"warning: {warning}")
