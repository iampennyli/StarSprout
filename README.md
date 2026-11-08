# 运动星球（StarSprout）· iOS MVP

儿童运动打卡 App 的第一版：跳绳、跑步打卡，运动了才有水浇小树，达标才有金币和零花钱 / 屏幕时间。
SwiftUI + SwiftData，iOS 17+，单设备，数据只存在本机，不需要服务器。

## 运行

需要 Mac + Xcode 15 或以上。

```bash
brew install xcodegen      # 只需装一次
cd StarSprout
xcodegen                   # 根据 project.yml 生成 StarSprout.xcodeproj
open StarSprout.xcodeproj
```

签名已配好：Bundle ID `li.penny.starsprout`，Team `3R3Q558848`，Xcode 自动签名（证书和描述文件由 Xcode 自动生成、续期）。
第一次真机运行前，在 Xcode → Settings → Accounts 登录这个开发者账号，手机用数据线连上 Mac 并在手机上点「信任」，
手机需打开「设置 → 隐私与安全性 → 开发者模式」。之后选你的 iPhone 运行即可。`⌘U` 运行引擎单元测试。

不想装 XcodeGen：在 Xcode 新建一个 iOS App（SwiftUI、Storage 选 None、最低 iOS 17），
删除自动生成的 ContentView 和 App 文件，把 `StarSprout/` 文件夹整个拖进去即可。

## 目录

| 目录 | 内容 |
| --- | --- |
| `Model/` | SwiftData 模型：设置、任务、打卡、账本流水、兑现申请、树、勋章 |
| `Engine/Economy.swift` | 所有数值（水、金币、施肥、阶段门槛），调数值只改这里 |
| `Engine/GameEngine.swift` | 奖励与养成规则：打卡结算、浇水施肥、周全勤、家长审批、目标建议、勋章统计 |
| `Engine/Medals.swift` | 勋章目录（坚持 / 跳绳 / 跑步 / 成长 / 突破 / 隐藏） |
| `Engine/NotificationManager.swift` | 本地提醒，每次打开、打卡、改任务后重排未来 7 天 |
| `Kid/` | 孩子端：今日任务 + 月历、跳绳计时 / 跑步打卡、打卡成功、星球（含动画）、宝库 + 勋章墙、勋章仪式和分享 |
| `Parent/` | 家长端：密码门、审批与统计、任务编辑、奖励设置 |
| `Onboarding/` | 首次使用引导（监护人同意 + 第一个任务） |
| `StarSproutTests/` | 引擎单元测试 |

## 已实现的规则

- 当天运动一次（不论达标）→ 水壶装满 3 次水，当天有效；浇水成长 +1
- 每次达标 → +10 金币（立即到账）+ 家长设的零花钱或屏幕时间（默认等家长确认，受每日上限约束）
- 破纪录 +20 金币（家长确认）；一周打卡满 5 天 +30 金币
- 施肥 30 金币，成长 +3，3 天一次
- 7 个成长阶段：0 / 3 / 12 / 36 / 100 / 170 / 240
- 树不会死：3–4 天口渴、5–9 天打瞌睡、10 天以上冬眠；回来后第一次浇水成长翻倍
- 1 分钟超过 220 个视为可疑，即使开了信任模式也要家长核实
- 勋章只看累计；一次打开最多播一场解锁仪式；分享卡只显示昵称，分享前需家长密码

## 还没做 / 需要替换

- 美术：树、星球、小兔子目前是基础图形占位，正式版换成 Lottie / Rive 动画
- 字体：标题用系统圆体，如需 ZCOOL 青刻黄油体要打包字体文件
- 分享卡二维码、App 名称、隐私政策和儿童个人信息保护规则正文
- 新种子、星球装饰、扩建、星果兑换（第二阶段）
- 屏幕时间自动管控（需要 Family Controls 权限，第二阶段）
