#!/usr/bin/env bash
# 输出最新 iOS 版本里一台标准尺寸 iPhone 模拟器的 UDID（优先 Pro，避开折叠屏 / Max / SE）
# SIM_NAME 可指定机型，如 SIM_NAME="iPhone 17"
xcrun simctl list devices available -j | python3 -c "
import json, os, re, sys
want = os.environ.get('SIM_NAME', '')
d = json.load(sys.stdin)['devices']
def ver(k):
    m = re.search(r'iOS-(\d+)-(\d+)', k)
    return (int(m.group(1)), int(m.group(2))) if m else (0, 0)
def score(name):
    if re.search(r'Fold|Flip|Max|Plus|SE|mini|Air', name): return 0
    if re.fullmatch(r'iPhone \d+ Pro', name): return 3
    if re.fullmatch(r'iPhone \d+', name): return 2
    return 1
best = None
for k in sorted((k for k in d if 'iOS' in k), key=ver, reverse=True):
    for dev in d[k]:
        n = dev['name']
        if not n.startswith('iPhone'): continue
        if want:
            if n == want: print(dev['udid']); sys.exit(0)
            continue
        s = (score(n), ver(k))
        if best is None or s > best[0]: best = (s, dev['udid'], n)
if best:
    print(best[1]); print('选中 ' + best[2], file=sys.stderr); sys.exit(0)
sys.exit('找不到可用的 iPhone 模拟器')
"
