#!/bin/bash
set -euo pipefail

VERSION="${1:?Usage: ./scripts/release.sh <version> e.g. 1.1}"
BUILD="${2:-$(date +%Y%m%d%H%M)}"
APP_NAME="BarbieTasks"
ARCHIVE_NAME="SlayList-${VERSION}"
SCHEME="BarbieTasks"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"

echo "=== Building Slay List v${VERSION} (build ${BUILD}) ==="

# Step 1: Update version numbers in project.yml
sed -i '' "s/MARKETING_VERSION: .*/MARKETING_VERSION: \"${VERSION}\"/" "${PROJECT_DIR}/project.yml"
sed -i '' "s/CURRENT_PROJECT_VERSION: .*/CURRENT_PROJECT_VERSION: \"${BUILD}\"/" "${PROJECT_DIR}/project.yml"

# Step 2: Regenerate xcodeproj
echo "Regenerating Xcode project..."
cd "${PROJECT_DIR}"
xcodegen generate

# Step 3: Resolve packages and build
echo "Building Release..."
mkdir -p "${BUILD_DIR}"
xcodebuild -scheme "${SCHEME}" \
  -destination 'platform=macOS' \
  -configuration Release \
  -derivedDataPath "${BUILD_DIR}/DerivedData" \
  clean build \
  MARKETING_VERSION="${VERSION}" \
  CURRENT_PROJECT_VERSION="${BUILD}"

# Step 4: Find the built .app
APP_PATH="${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app"
if [ ! -d "${APP_PATH}" ]; then
  echo "ERROR: Built app not found at ${APP_PATH}"
  exit 1
fi

echo "App built: ${APP_PATH}"

# Step 5: Create zip for distribution
ZIP_PATH="${BUILD_DIR}/${ARCHIVE_NAME}.zip"
cd "$(dirname "${APP_PATH}")"
ditto -c -k --keepParent "$(basename "${APP_PATH}")" "${ZIP_PATH}"
echo "Zip created: ${ZIP_PATH}"

# Step 6: Try to sign with Sparkle's EdDSA key
SIGN_TOOL=""
for dir in "${BUILD_DIR}"/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin \
           ~/Library/Developer/Xcode/DerivedData/BarbieTasks-*/SourcePackages/artifacts/sparkle/Sparkle/bin; do
  if [ -x "${dir}/sign_update" ] 2>/dev/null; then
    SIGN_TOOL="${dir}/sign_update"
    break
  fi
done

if [ -n "${SIGN_TOOL}" ]; then
  echo ""
  echo "=== Signing with Sparkle EdDSA ==="
  SIGNATURE=$("${SIGN_TOOL}" "${ZIP_PATH}")
  echo "${SIGNATURE}"
else
  echo ""
  echo "WARNING: sign_update tool not found. You'll need to sign manually."
  echo "After building in Xcode, find it in DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/"
  SIGNATURE="sparkle:edSignature=\"SIGN_ME\" length=\"$(stat -f%z "${ZIP_PATH}")\""
fi

FILE_SIZE=$(stat -f%z "${ZIP_PATH}")
PUB_DATE=$(date -R 2>/dev/null || date "+%a, %d %b %Y %H:%M:%S %z")

echo ""
echo "=== Appcast entry ==="
echo "Add this <item> to appcast.xml:"
echo ""
cat <<APPCAST
    <item>
      <title>Version ${VERSION}</title>
      <sparkle:version>${BUILD}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <pubDate>${PUB_DATE}</pubDate>
      <description><![CDATA[
        <h2>What's New in ${VERSION}</h2>
        <ul>
          <li>UPDATE RELEASE NOTES HERE</li>
        </ul>
      ]]></description>
      <enclosure
        url="https://github.com/mappy4ever/GlammerPlanner/releases/download/v${VERSION}/${ARCHIVE_NAME}.zip"
        type="application/octet-stream"
        ${SIGNATURE}
      />
    </item>
APPCAST

echo ""
echo "=== Next steps ==="
echo "1. Update appcast.xml with the entry above"
echo "2. Commit and push appcast.xml"
echo "3. Create GitHub release:"
echo "   gh release create v${VERSION} '${ZIP_PATH}' --title 'Slay List v${VERSION}' --notes 'Release notes here'"
echo ""
echo "Or copy the app to Desktop:"
echo "   cp -R '${APP_PATH}' ~/Desktop/"
