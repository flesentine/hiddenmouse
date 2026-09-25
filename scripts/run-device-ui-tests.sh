#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p TestResults

SIMULATOR_JSON="$(xcrun simctl list devices available -j)"

SELECTED="$(
  printf '%s' "$SIMULATOR_JSON" | python3 -c '
import json
import re
import sys

data = json.load(sys.stdin)

devices = []
for runtime, runtime_devices in data.get("devices", {}).items():
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    version = (int(match.group(1)), int(match.group(2))) if match else (999, 999)
    for device in runtime_devices:
        name = device.get("name", "")
        if not name.startswith("iPhone"):
            continue
        if not device.get("isAvailable", True):
            continue
        devices.append({
            "name": name,
            "udid": device["udid"],
            "runtime": runtime,
            "version": version,
        })

if len(devices) < 3:
    raise SystemExit("Need at least three available iPhone simulators for device testing.")

used = set()

def choose(label, preferred_names, classifier):
    candidates = [d for d in devices if d["udid"] not in used]
    preferred = [d for d in candidates if d["name"] in preferred_names]
    classified = [d for d in candidates if classifier(d["name"])]
    pool = preferred or classified or candidates

    # Prefer the oldest available runtime for the compact profile so the
    # matrix exercises an older supported environment when the runner has one.
    if label == "compact":
        pool = sorted(
            pool,
            key=lambda d: (
                d["version"],
                preferred_names.index(d["name"]) if d["name"] in preferred_names else 999,
                d["name"],
            ),
        )
    else:
        pool = sorted(
            pool,
            key=lambda d: (
                preferred_names.index(d["name"]) if d["name"] in preferred_names else 999,
                tuple(-x for x in d["version"]),
                d["name"],
            ),
        )

    selected = pool[0]
    used.add(selected["udid"])
    runtime_label = selected["runtime"].split(".")[-1].replace("iOS-", "iOS ").replace("-", ".")
    print("{}|{}|{}|{}".format(label, selected["name"], selected["udid"], runtime_label))

choose(
    "compact",
    ["iPhone SE (3rd generation)", "iPhone 13 mini", "iPhone 16e"],
    lambda name: "SE" in name or "mini" in name or name.endswith("16e"),
)
choose(
    "standard",
    ["iPhone 16", "iPhone 15", "iPhone 14"],
    lambda name: all(token not in name for token in ["Pro Max", "Plus", "SE", "mini"]),
)
choose(
    "large",
    ["iPhone 16 Pro Max", "iPhone 15 Pro Max", "iPhone 14 Pro Max", "iPhone 16 Plus", "iPhone 15 Plus"],
    lambda name: "Pro Max" in name or "Plus" in name,
)
'
)"

echo "Selected device test matrix:"
printf '%s\n' "$SELECTED" | sed 's/^/  /'

FAILURES=0

while IFS='|' read -r PROFILE NAME UDID RUNTIME; do
  RESULT_PATH="TestResults/${PROFILE}.xcresult"

  echo
  echo "=== ${PROFILE}: ${NAME} (${RUNTIME}) ==="

  rm -rf "$RESULT_PATH"
  xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
  xcrun simctl boot "$UDID" >/dev/null 2>&1 || true

  if ! python3 scripts/run-command-with-timeout.py \
    120 \
    xcrun simctl bootstatus "$UDID" -b; then
    echo "FAIL: ${PROFILE} — ${NAME} simulator boot timed out or failed"
    FAILURES=$((FAILURES + 1))
    xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
    continue
  fi

  if python3 scripts/run-command-with-timeout.py \
    360 \
    xcodebuild \
    -project ParkHunt.xcodeproj \
    -scheme ParkHunt \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$UDID" \
    CODE_SIGNING_ALLOWED=NO \
    -only-testing:ParkHuntUITests \
    -resultBundlePath "$RESULT_PATH" \
    test; then
    echo "PASS: ${PROFILE} — ${NAME}"
  else
    echo "FAIL: ${PROFILE} — ${NAME}"
    FAILURES=$((FAILURES + 1))
  fi

  xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
done <<< "$SELECTED"

echo
if [ "$FAILURES" -ne 0 ]; then
  echo "Device UI matrix failed on $FAILURES profile(s)."
  exit 1
fi

echo "Device UI matrix passed on all selected iPhone profiles."
