#!/usr/bin/env bash
# 在模拟器里用演示数据逐页截图，输出到 build/screenshots/
# 用法：./scripts/screenshots.sh                   （全部页面）
#       ./scripts/screenshots.sh today planet      （只截指定页面）
# 页面名见 StarSprout/App/DemoMode.swift 里的 DemoScreen
set -euo pipefail
cd "$(dirname "$0")/.."

BUNDLE=li.penny.starsprout
OUT=build/screenshots
SCREENS=("$@")
[ ${#SCREENS[@]} -eq 0 ] && SCREENS=(onboarding today planet vault session success medal share pin parent parentTasks parentRewards trees shop)

command -v xcodegen >/dev/null 2>&1 || brew install xcodegen
xcodegen generate --quiet

UDID=$(./scripts/pick-sim.sh)
echo "== 模拟器 $UDID =="
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 \
  --cellularBars 4 --wifiBars 3 2>/dev/null || true

mkdir -p build/logs "$OUT"
echo "== 编译 App =="
xcodebuild build -project StarSprout.xcodeproj -scheme StarSprout \
  -destination "id=$UDID" -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO \
  > build/logs/screenshots-build.log 2>&1 || { grep -E "error:" build/logs/screenshots-build.log | sort -u; exit 1; }
APP=build/DerivedData/Build/Products/Debug-iphonesimulator/StarSprout.app
xcrun simctl install "$UDID" "$APP"
# 截图不需要通知权限弹窗打断
xcrun simctl privacy "$UDID" grant notifications "$BUNDLE" 2>/dev/null || true

for s in "${SCREENS[@]}"; do
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" -screen "$s" -AppleLanguages "(zh-Hans)" -AppleLocale zh_CN >/dev/null
  sleep "${SHOT_DELAY:-4}"
  xcrun simctl io "$UDID" screenshot --type=png "$OUT/$s.png" >/dev/null 2>&1
  echo "截图 $s"
done
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
echo "== 完成：$OUT =="
