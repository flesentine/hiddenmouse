#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <source-image> <asset-stem>"
  echo "Example: $0 ~/Desktop/pirates-secret.jpg pirates-secret-001"
  exit 64
fi

source_image="$1"
asset_stem="$2"
output_dir="ParkHunt/Resources/Images"

if [[ ! -f "$source_image" ]]; then
  echo "Source image not found: $source_image"
  exit 66
fi

if [[ ! "$asset_stem" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Asset stem may contain only letters, numbers, dot, underscore, and hyphen."
  exit 65
fi

mkdir -p "$output_dir"

thumbnail="$output_dir/${asset_stem}-thumb.jpg"
reveal="$output_dir/${asset_stem}-reveal.jpg"

sips \
  -Z 320 \
  -s format jpeg \
  -s formatOptions normal \
  "$source_image" \
  --out "$thumbnail" >/dev/null

sips \
  -Z 1600 \
  -s format jpeg \
  -s formatOptions high \
  "$source_image" \
  --out "$reveal" >/dev/null

echo "Created:"
echo "  $thumbnail"
echo "  $reveal"
echo
echo "Catalog fields:"
echo "  \"thumbnailImageName\": \"${asset_stem}-thumb.jpg\","
echo "  \"revealImageName\": \"${asset_stem}-reveal.jpg\""
