#!/bin/bash
set -euo pipefail

MODE="${1:-signed}"

python3 scripts/validate-content-admin.py --field-test
python3 scripts/build-content-catalog.py --check
python3 scripts/verify-field-test-build.py

export BUILD_CONFIGURATION=FieldTest
export ARCHIVE_PATH="${ARCHIVE_PATH:-Build/FieldTest/ParkHunt.xcarchive}"
export EXPORT_PATH="${EXPORT_PATH:-Build/FieldTest/export}"

exec ./scripts/build-testflight-archive.sh "$MODE"
