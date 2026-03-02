#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 5 ]; then
  echo "usage: $0 <version> <release_base_url> <darwin_arm64_url> <darwin_arm64_sha256> <darwin_arm64_asset_name>" >&2
  exit 1
fi

VERSION="$1"
RELEASE_BASE_URL="$2"
DARWIN_URL="$3"
DARWIN_SHA="$4"
DARWIN_ASSET_NAME="$5"

cat > manifest.json <<EOF
{
  "version": "${VERSION}",
  "assets": {
    "darwin-arm64": {
      "url": "${DARWIN_URL}",
      "sha256": "${DARWIN_SHA}"
    }
  }
}
EOF

cat > checksums.txt <<EOF
${DARWIN_SHA}  ${DARWIN_ASSET_NAME}
EOF

echo "manifest.json and checksums.txt generated for ${VERSION} at ${RELEASE_BASE_URL}"
