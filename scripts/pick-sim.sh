#!/usr/bin/env bash
# 输出最新 iOS 版本里第一台 iPhone 模拟器的 UDID；SIM_NAME 可指定机型
xcrun simctl list devices available -j | python3 -c "
import json, os, re, sys
want = os.environ.get('SIM_NAME', '')
d = json.load(sys.stdin)['devices']
def ver(k):
    m = re.search(r'iOS-(\d+)-(\d+)', k)
    return (int(m.group(1)), int(m.group(2))) if m else (0, 0)
for k in sorted((k for k in d if 'iOS' in k), key=ver, reverse=True):
    for dev in d[k]:
        if dev['name'].startswith('iPhone') and (not want or dev['name'] == want):
            print(dev['udid']); sys.exit(0)
sys.exit('找不到可用的 iPhone 模拟器')
"
