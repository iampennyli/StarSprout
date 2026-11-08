#!/usr/bin/env bash
# 一次性脚本：把这台 Mac 注册成 iampennyli/StarSprout 的 GitHub Actions 自托管 runner。
# 之后每次推送代码，都会在这台 Mac 上用本机 Xcode 自动编译和测试。
#
# 1. 打开 https://github.com/iampennyli/StarSprout/settings/actions/runners/new?arch=arm64&os=osx
# 2. 复制页面上 ./config.sh 那一行里 --token 后面的令牌
# 3. 运行：bash setup-local-runner.sh <令牌>
set -euo pipefail

TOKEN="${1:-}"
if [ -z "$TOKEN" ]; then
  read -r -p "粘贴 GitHub 页面上的 runner 令牌：" TOKEN
fi
REPO_URL="https://github.com/iampennyli/StarSprout"
DIR="$HOME/actions-runner-starsprout"

mkdir -p "$DIR" && cd "$DIR"
if [ ! -f ./config.sh ]; then
  VERSION=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'].lstrip('v'))")
  echo "下载 GitHub Actions runner $VERSION ..."
  curl -fsSL -o runner.tar.gz "https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-osx-arm64-${VERSION}.tar.gz"
  tar xzf runner.tar.gz && rm runner.tar.gz
fi

./config.sh --unattended --replace \
  --url "$REPO_URL" \
  --token "$TOKEN" \
  --name "$(scutil --get LocalHostName)-starsprout" \
  --labels "starsprout" \
  --work "_work"

# 安装成登录后自动在后台运行的服务（需要能打开模拟器，所以用当前用户的登录会话）
./svc.sh install
./svc.sh start
./svc.sh status
echo
echo "完成：这台 Mac 已注册为 StarSprout 的 runner。以后推送代码会自动在本机构建测试。"
echo "停用：cd $DIR && ./svc.sh stop && ./svc.sh uninstall"
