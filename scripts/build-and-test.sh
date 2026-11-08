#!/usr/bin/env bash
# 在本机用 Xcode 编译运动星球并跑单元测试。
# 用法：./scripts/build-and-test.sh            （自动选最新的 iPhone 模拟器）
#       SIM_NAME="iPhone 17" ./scripts/build-and-test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== Xcode =="
xcodebuild -version

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "== 安装 XcodeGen =="
  brew install xcodegen
fi
echo "== 生成工程 =="
xcodegen generate --quiet

echo "== 选择模拟器 =="
UDID=$(./scripts/pick-sim.sh)
echo "使用模拟器 $UDID"

mkdir -p build/logs
LOG="build/logs/test-$(date +%Y%m%d-%H%M%S).log"
echo "== 编译并测试（完整日志：${LOG}）=="
set +e
xcodebuild test \
  -project StarSprout.xcodeproj \
  -scheme StarSprout \
  -destination "id=$UDID" \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  > "$LOG" 2>&1
STATUS=$?
set -e

echo "== 结果 =="
grep -E "error:|Test Case .*(passed|failed)|\*\* (BUILD|TEST) (SUCCEEDED|FAILED) \*\*" "$LOG" | grep -v "CoreData" | sort -u || true
echo "== 警告 =="
grep -E "warning:" "$LOG" | grep -v "CoreData" | sed "s#.*/StarSprout/##" | sort -u | head -30 || true
exit $STATUS
