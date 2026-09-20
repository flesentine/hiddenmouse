#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodegen >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required before XcodeGen can be installed."
    echo "Install it from https://brew.sh, then rerun ./bootstrap.sh."
    exit 1
  fi
  brew install xcodegen
fi

xcodegen generate
open ParkHunt.xcodeproj
