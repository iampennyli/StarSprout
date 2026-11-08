# 运动星球（StarSprout）· 给 Claude Code 的接手说明

儿童运动打卡 iOS App：孩子跳绳 / 跑步打卡，运动了才有水浇小树，达标才有金币和零花钱 / 屏幕时间。
目标用户 6–12 岁孩子 + 家长，单设备（家长手机），家长模式用 4 位密码进入。

## 常用命令

```bash
./scripts/build-and-test.sh                 # 生成工程 + 选最新 iPhone 模拟器 + 编译 + 跑单元测试
SIM_NAME="iPhone 17" ./scripts/build-and-test.sh
./scripts/screenshots.sh [today planet …]  # 演示数据 + 模拟器逐页截图 → build/screenshots/
python3 scripts/sound/generate_sounds.py  # 重新合成背景音乐和音效（numpy + scipy + ffmpeg）
xcodegen generate && open StarSprout.xcodeproj
```

- 演示模式：启动参数 `-demo` 用内存数据库预置一个月数据，`-screen <页面>` 直达某页（`App/DemoMode.swift`）。改了界面后跑截图脚本自查。CI 也会截图并推到 `screenshots` 分支。

- 工程由 `project.yml`（XcodeGen）生成，`StarSprout.xcodeproj` 不进仓库；新增文件放进 `StarSprout/` 对应目录即可，不要手改 pbxproj。
- 完整构建日志在 `build/logs/`。改完代码必须跑一遍脚本，测试全过再提交。
- 推送到 `main` 会触发 GitHub Actions，在本机自托管 runner（标签 `starsprout`，目录 `~/actions-runner-starsprout`）上跑同一个脚本。

## 技术栈与结构

SwiftUI + SwiftData，iOS 17+，Swift 5 语言模式，无服务器、无第三方依赖。

| 目录 | 职责 |
| --- | --- |
| `Model/Models.swift` | SwiftData 模型。枚举以 raw string 存储（`kindRaw` 等），加字段务必给默认值，避免迁移失败 |
| `Engine/Economy.swift` | **所有数值的唯一出处**（水、金币、施肥、阶段门槛）。调数值只改这里 |
| `Engine/GameEngine.swift` | **所有奖励与养成规则**。界面只调用引擎，不自己算账 |
| `Engine/Medals.swift` | 勋章目录与判定 |
| `Engine/NotificationManager.swift` | 本地通知，重排未来 7 天，当天已运动则跳过 |
| `Engine/SoundManager.swift` | 星球页背景音乐（无缝循环、淡入淡出）+ 音效；`.ambient` 会话遵从静音键；开关在 UserDefaults |
| `Resources/Sounds/` | 由 `scripts/sound/generate_sounds.py` 程序合成的音频，**不要手工替换**，改脚本参数后重新生成 |
| `Kid/` | 孩子端：今日任务 + 月历、打卡流程、打卡成功、星球（动画）、宝库 + 勋章 |
| `Parent/` | 家长端：密码门、审批统计、任务编辑、奖励设置 |
| `Onboarding/` | 首次引导（监护人同意 + 第一个任务） |
| `StarSproutTests/` | 引擎单元测试（内存 SwiftData 容器） |

## 产品规则（改动前先确认不违背）

1. **树只会长大，不会死**。3–4 天没运动口渴、5–9 天打瞌睡、10 天以上冬眠：只暂停开花结果，成长值不减；回来后第一次浇水成长翻倍。
2. **水和金币分开**：当天运动一次（不论达标）水壶装满 3 次，当天有效不能攒；金币只在达标 / 破纪录 / 周全勤时给，可以攒，不能换钱。
3. **努力和成就分开奖励**：动了就有水；达标才有金币和真实奖励。
4. 水和金币**立即到账**；零花钱和屏幕时间**等家长确认**（信任模式除外），受每日上限约束。
5. 浇水每天最多 3 次（+1），施肥 30 金币 +3、3 天一次；每天成长最多 +6。
6. **不惩罚、不强调连续**：没有断签，日历不标红叉，文案不提"你几天没来"。
7. 勋章只看累计，拿到就永远是你的；一次打开最多播一场解锁仪式。
8. 1 分钟跳绳超过 220 个视为可疑，即使信任模式也要家长核实；破纪录金币需家长确认。
9. **儿童隐私**：只存昵称和年龄段，数据只在本机；分享卡不出现真名、照片、学校，分享前要家长密码。不接第三方统计 / 广告 SDK（App Store 儿童类别要求）。
10. App 只记账：不处理真钱，不直接控制其他 App 的屏幕时间。

## 设计规范

星际探险风格：深蓝星空底 `#171A3D`，卡片 `#23275A` + 描边 `#3A3F80`，主操作荧光绿 `#B8F25B`（深色字），零花钱薄荷绿 `#8BE3A0`，屏幕时间/水青色 `#5BE0F2`，金币金色 `#FFC94D`。token 都在 `Design/Theme.swift`，不要在页面里写新颜色。触控目标 ≥ 44pt，标题用圆体粗体。

## 参考资料

- 需求文档（PRD）：https://claude.ai/artifact/88PFdWb2n1TU71wJtYx7AN
- 交互设计画布：https://claude.ai/artifact/HQ3KCSqutpPYibjAcWkKkR

## 已知待办

- 美术：树（7 阶段 × 4 状态，带表情）、星球、草地、小兔子已用 SwiftUI 矢量重画（`Kid/TreeView.swift`、`Kid/PlanetArt.swift`，插画专用色写在这两个文件里）。`-screen trees` 是美术检查页。将来要更细腻的动效再考虑 Lottie / Rive
- 分享卡二维码、App 正式名称、隐私政策和儿童个人信息保护规则正文
- 第二阶段：新种子、星球装饰、扩建、星果兑换真实奖励、屏幕时间自动管控（Family Controls）
- 界面已用 `scripts/screenshots.sh` 逐页截图检查过一轮（2026-11-08）；美术替换后需再过一遍

## 提交约定

提交信息用中文，一句话说清改了什么；改了规则或数值时同步更新单元测试和本文件。
