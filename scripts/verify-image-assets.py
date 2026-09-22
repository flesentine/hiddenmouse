#!/usr/bin/env python3
import json
import sys
from pathlib import Path

CATALOG_PATH = Path("ParkHunt/Resources/content-catalog.json")
IMAGE_DIR = Path("ParkHunt/Resources/Images")
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".heic", ".png"}
MAX_BYTES = {
    "thumbnailImageName": 400 * 1024,
    "revealImageName": 2 * 1024 * 1024,
}

with CATALOG_PATH.open("r", encoding="utf-8") as handle:
    catalog = json.load(handle)

errors = []

for discovery in catalog.get("discoveries", []):
    discovery_id = discovery.get("id", "<missing-id>")

    for field, max_bytes in MAX_BYTES.items():
        name = discovery.get(field)
        if not name:
            continue

        if Path(name).name != name:
            errors.append(
                f"{discovery_id}: {field} must be a filename only: {name}"
            )
            continue

        suffix = Path(name).suffix.lower()
        if suffix not in ALLOWED_EXTENSIONS:
            errors.append(
                f"{discovery_id}: unsupported image type for {field}: {name}"
            )
            continue

        path = IMAGE_DIR / name
        if not path.is_file():
            errors.append(
                f"{discovery_id}: missing packaged image for {field}: {path}"
            )
            continue

        size = path.stat().st_size
        if size > max_bytes:
            errors.append(
                f"{discovery_id}: {field} is {size} bytes; max is {max_bytes}: {name}"
            )

if errors:
    print("Image asset verification failed:")
    for error in errors:
        print(f"  - {error}")
    sys.exit(1)

print("Image asset verification passed.")
