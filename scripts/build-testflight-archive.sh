#!/bin/bash
set -euo pipefail

MODE="\${1:-signed}"
BUILD_NUMBER="\${BUILD_NUMBER:-}"
TEAM_ID="\${TEAM_ID:-}"
ARCHIVE_PATH="\${ARCHIVE_PATH:-Build/TestFlight/ParkHunt.xcarchive}"
EXPORT_PATH="\${EXPORT_PATH:-Build/TestFlight/export}"

if [[ "$MODE" != "signed" && "$MODE" != "--ci-unsigned" ]]; then
  echo "Usage: $0 [signed|--ci-unsigned]"
  exit 2
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required."
  exit 2
fi

xcodegen generate

COMMON_ARGS=(
  -project ParkHunt.xcodeproj
  -scheme ParkHunt
  -configuration Release
  -destination "generic/platform=iOS"
  -archivePath "$ARCHIVE_PATH"
)

if [[ -n "$BUILD_NUMBER" ]]; then
  COMMON_ARGS+=(CURRENT_PROJECT_VERSION="$BUILD_NUMBER")
fi

rm -rf "$ARCHIVE_PATH"

if [[ "$MODE" == "--ci-unsigned" ]]; then
  xcodebuild "\${COMMON_ARGS[@]}" CODE_SIGNING_ALLOWED=NO archive
  test -d "$ARCHIVE_PATH"
  echo "Unsigned Release archive created at $ARCHIVE_PATH"
  exit 0
fi

if [[ -z "$TEAM_ID" ]]; then
  echo "TEAM_ID is required for a signed TestFlight archive."
  echo "Example: TEAM_ID=ABCDE12345 BUILD_NUMBER=2 $0 signed"
  exit 2
fi

xcodebuild \
  "\${COMMON_ARGS[@]}" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  -allowProvisioningUpdates \
  archive

rm -rf "$EXPORT_PATH"
mkdir -p "$EXPORT_PATH"

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist Config/ExportOptions-TestFlight.plist \
  -allowProvisioningUpdates

echo "Signed App Store Connect export created at $EXPORT_PATH"
echo "Upload the exported build with Xcode Organizer / App Store Connect using your authorized Apple account."
