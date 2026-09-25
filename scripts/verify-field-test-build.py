#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

errors = []

project = Path("project.yml")
field_config = Path("Config/FieldTest.xcconfig")
version = Path("Config/Version.xcconfig")
discoveries_dir = Path("ContentAdmin/discoveries")
registry_path = Path("ContentAdmin/discovery-id-registry.json")
field_build_script = Path("scripts/build-field-test.sh")
icon_path = Path("ParkHunt/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")

for path in [
    project,
    field_config,
    version,
    registry_path,
    field_build_script,
    icon_path,
]:
    if not path.exists():
        errors.append(f"{path}: missing")

project_text = project.read_text(encoding="utf-8") if project.exists() else ""
field_text = field_config.read_text(encoding="utf-8") if field_config.exists() else ""
version_text = version.read_text(encoding="utf-8") if version.exists() else ""

if "FieldTest: release" not in project_text:
    errors.append("project.yml: FieldTest configuration is not registered")
if "FieldTest: Config/FieldTest.xcconfig" not in project_text:
    errors.append("project.yml: FieldTest config file is not wired")
if "PARKHUNT_FIELD_TEST" not in field_text:
    errors.append("Config/FieldTest.xcconfig: PARKHUNT_FIELD_TEST is missing")
if 'PARKHUNT_ENVIRONMENT = field-test' not in field_text:
    errors.append("Config/FieldTest.xcconfig: field-test environment marker is missing")

discoveries = []
if discoveries_dir.is_dir():
    for path in sorted(discoveries_dir.glob("*.json")):
        try:
            discoveries.append(json.loads(path.read_text(encoding="utf-8")))
        except Exception as exc:
            errors.append(f"{path}: invalid JSON ({exc})")
else:
    errors.append(f"{discoveries_dir}: missing")

registry = {}
if registry_path.exists():
    try:
        registry = json.loads(registry_path.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{registry_path}: invalid JSON ({exc})")

if len(discoveries) < 18:
    errors.append(
        f"Field-test catalog has {len(discoveries)} discoveries; expected at least the 18 New Orleans Square hunts"
    )

status_counts = {}
for discovery in discoveries:
    status = discovery.get("verificationStatus")
    status_counts[status] = status_counts.get(status, 0) + 1

    if status == "unverified":
        errors.append(
            f"{discovery.get('id', '<missing>')}: unverified content cannot enter a field-test build"
        )

    editorial = discovery.get("_editorial")
    if isinstance(editorial, dict) and editorial.get("developmentOnly"):
        errors.append(
            f"{discovery.get('id', '<missing>')}: development-only content cannot enter a field-test build"
        )

    discovery_id = discovery.get("id")
    entry = registry.get(discovery_id, {}) if isinstance(registry, dict) else {}
    if entry.get("state") != "active":
        errors.append(
            f"{discovery_id}: field-test discovery must have active registry state"
        )

marketing = re.search(r"^MARKETING_VERSION\s*=\s*([^\s]+)", version_text, re.MULTILINE)
build = re.search(r"^CURRENT_PROJECT_VERSION\s*=\s*(\d+)", version_text, re.MULTILINE)

if errors:
    print("Disneyland field-test build verification failed:")
    for error in errors:
        print(f"  - {error}")
    sys.exit(1)

print("Disneyland field-test build verification passed.")
print(f"Discoveries: {len(discoveries)}")
print(
    "Verification statuses: "
    + ", ".join(
        f"{key}={value}"
        for key, value in sorted(status_counts.items())
    )
)
if marketing and build:
    print(f"Build metadata: {marketing.group(1)} ({build.group(1)})")
