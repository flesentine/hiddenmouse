#!/bin/bash
set -euo pipefail

# The prototype's core hunt loop must remain fully usable without network access.
# Fail CI if a networking API or hard-coded remote URL is introduced into app
# source/content. System settings URLs are not network requests and are not
# matched by these patterns.
patterns=(
  'URLSession'
  'URLRequest'
  'AsyncImage'
  'import Network'
  'NWConnection'
  'Alamofire'
  'http://'
  'https://'
)

for pattern in "${patterns[@]}"; do
  if grep -RInF     --include='*.swift'     --include='*.json'     --exclude-dir='.build'     "$pattern"     ParkHunt; then
    echo "Offline-core verification failed: found forbidden pattern '$pattern'."
    exit 1
  fi
done

echo "Offline-core verification passed: no networking dependency found."
