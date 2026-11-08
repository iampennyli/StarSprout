#!/usr/bin/env bash
# 打包运动星球并上传到 App Store Connect（之后在 TestFlight 里出现）。
# 用法：./scripts/testflight.sh
#
# 前提（只需一次）：
#   1. Xcode → Settings → Accounts 已登录开发者账号（Team 3R3Q558848）
#   2. App Store Connect 里已经建好 Bundle ID 为 li.penny.starsprout 的 App
# 签名、证书、描述文件都由 Xcode 自动处理（-allowProvisioningUpdates）。
# 构建号用当前时间（如 202611081630），保证每次上传都不重复。
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_NUMBER=${BUILD_NUMBER:-$(date +%Y%m%d%H%M)}
ARCHIVE=build/StarSprout.xcarchive
EXPORT=build/export
mkdir -p build/logs

command -v xcodegen >/dev/null 2>&1 || brew install xcodegen
xcodegen generate --quiet

echo "== 归档（Release，构建号 $BUILD_NUMBER）=="
rm -rf "$ARCHIVE" "$EXPORT"
xcodebuild archive \
  -project StarSprout.xcodeproj -scheme StarSprout -configuration Release \
  -destination "generic/platform=iOS" -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  > build/logs/archive.log 2>&1 || { grep -E "error:" build/logs/archive.log | sort -u; echo "归档失败，完整日志：build/logs/archive.log"; exit 1; }

cat > build/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>3R3Q558848</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>testFlightInternalTestingOnly</key><false/>
</dict>
</plist>
PLIST

echo "== 上传到 App Store Connect =="
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" -exportPath "$EXPORT" \
  -exportOptionsPlist build/ExportOptions.plist \
  -allowProvisioningUpdates \
  > build/logs/upload.log 2>&1 || { grep -E "error|Error" build/logs/upload.log | sort -u | head -20; echo "上传失败，完整日志：build/logs/upload.log"; exit 1; }

echo "== 上传完成：版本 $(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleShortVersionString' "$ARCHIVE/Info.plist") ($BUILD_NUMBER) =="
echo "苹果处理大约需要 5–30 分钟，处理完会出现在 App Store Connect → TestFlight。"
