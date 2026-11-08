import SwiftUI

/// 星球上的小树：7 个成长阶段 + 4 种状态，全部用矢量图形绘制。
/// 固定画布 240×260，树根在底部中间；有一张会随状态变化的小脸，孩子照顾它时能看到它的情绪。
struct TreeView: View {
    var stage: Int
    var mood: TreeMood = .normal

    // MARK: Palette

    private var leafTop: Color {
        switch mood {
        case .normal: return Color(hex: 0xA6F5B4)
        case .thirsty: return Color(hex: 0xDCEB9E)
        case .sleepy, .hibernating: return Color(hex: 0x7CC29A)
        }
    }
    private var leafMid: Color {
        switch mood {
        case .normal: return Color(hex: 0x5ED488)
        case .thirsty: return Color(hex: 0xB4CE6C)
        case .sleepy, .hibernating: return Color(hex: 0x4E9672)
        }
    }
    private var leafShade: Color {
        switch mood {
        case .normal: return Color(hex: 0x37A867)
        case .thirsty: return Color(hex: 0x8DA84C)
        case .sleepy, .hibernating: return Color(hex: 0x346F54)
        }
    }
    private var leafFill: LinearGradient {
        LinearGradient(colors: [leafTop, leafMid], startPoint: .top, endPoint: .bottom)
    }
    private static let bark = LinearGradient(colors: [Color(hex: 0xD99A64), Color(hex: 0xA4683D), Color(hex: 0x86522E)],
                                             startPoint: .leading, endPoint: .trailing)
    private static let seedFill = LinearGradient(colors: [Color(hex: 0xE0A06A), Color(hex: 0x9C5F34)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)

    /// 各阶段植物的大致高度，用来摆放口渴 / 打瞌睡的提示
    private var plantHeight: CGFloat {
        switch stage {
        case ...1: return 40
        case 2: return 84
        case 3: return 150
        case 4: return 226
        default: return 252
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            switch stage {
            case ...1: seed
            case 2: sprout
            case 3: sapling
            case 4: tree(trunk: CGSize(width: 26, height: 96), canopy: CGSize(width: 160, height: 136), lift: 78)
            default: tree(trunk: CGSize(width: 34, height: 104), canopy: CGSize(width: 204, height: 168), lift: 84)
            }
        }
        .scaleEffect(x: 1, y: mood == .thirsty ? 0.96 : 1, anchor: .bottom)
        .frame(width: 240, height: 260, alignment: .bottom)
        .overlay(alignment: .topTrailing) { moodBadge }
        .accessibilityElement()
        .accessibilityLabel("小树，第 \(stage) 阶段" + (mood.message.map { "，\($0)" } ?? ""))
    }

    @ViewBuilder
    private var moodBadge: some View {
        let top = max(0, 260 - plantHeight - 10)
        switch mood {
        case .thirsty:
            Image(systemName: "drop.fill").font(.system(size: 20)).foregroundStyle(Theme.cyan)
                .padding(9).background(.white, in: Circle())
                .shadow(color: Theme.cyan.opacity(0.5), radius: 8)
                .padding(.top, top).padding(.trailing, stage >= 4 ? 14 : 60)
        case .sleepy, .hibernating:
            VStack(alignment: .leading, spacing: -4) {
                Text("z").font(.system(size: 26, weight: .heavy, design: .rounded))
                Text("z").font(.system(size: 18, weight: .heavy, design: .rounded)).padding(.leading, 14)
            }
            .foregroundStyle(Theme.muted)
            .padding(.top, top).padding(.trailing, stage >= 4 ? 18 : 64)
        case .normal:
            EmptyView()
        }
    }

    // MARK: Stage 1 · 种子

    private var seed: some View {
        ZStack {
            Ellipse().fill(Self.seedFill).frame(width: 50, height: 38)
            Ellipse().fill(.white.opacity(0.35)).frame(width: 12, height: 7).rotationEffect(.degrees(-25)).offset(x: -12, y: -10)
            TreeFace(mood: mood, scale: 0.55).offset(y: 3)
        }
        .padding(.bottom, 2)
    }

    // MARK: Stage 2 · 发芽

    private var sprout: some View {
        ZStack(alignment: .bottom) {
            StemCurve().stroke(leafShade, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 20, height: 56).padding(.bottom, 22)
            Leaf(fill: leafFill, vein: leafShade).frame(width: 40, height: 22)
                .rotationEffect(.degrees(-28)).offset(x: -18, y: -66)
            Leaf(fill: leafFill, vein: leafShade).frame(width: 44, height: 24)
                .rotationEffect(.degrees(200)).offset(x: 20, y: -72)
            ZStack {
                Ellipse().fill(Self.seedFill).frame(width: 46, height: 30)
                Ellipse().fill(.white.opacity(0.3)).frame(width: 10, height: 5).offset(x: -11, y: -7)
                TreeFace(mood: mood, scale: 0.5).offset(y: 2)
            }
        }
    }

    // MARK: Stage 3 · 小树苗

    private var sapling: some View {
        ZStack(alignment: .bottom) {
            TrunkShape().fill(Self.bark).frame(width: 16, height: 84)
            Leaf(fill: leafFill, vein: leafShade).frame(width: 30, height: 16)
                .rotationEffect(.degrees(-30)).offset(x: -16, y: -40)
            canopy(CGSize(width: 96, height: 82), face: 0.7)
                .padding(.bottom, 66)
        }
    }

    // MARK: Stage 4+ · 小树 / 大树 / 开花 / 结果

    private func tree(trunk: CGSize, canopy size: CGSize, lift: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            TrunkShape().fill(Self.bark).frame(width: trunk.width, height: trunk.height)
            // 一根小树枝，让树干不那么呆板
            Capsule().fill(Color(hex: 0xA4683D)).frame(width: trunk.width * 0.28, height: trunk.height * 0.42)
                .rotationEffect(.degrees(38), anchor: .bottom)
                .offset(x: trunk.width * 0.3, y: -trunk.height * 0.42)
            canopy(size, face: stage == 4 ? 1.0 : 1.2)
                .padding(.bottom, lift)
        }
    }

    private func canopy(_ size: CGSize, face: CGFloat) -> some View {
        ZStack {
            Blobs(circles: Self.canopyBlobs).fill(leafShade).offset(y: size.height * 0.05)
            Blobs(circles: Self.canopyBlobs).fill(leafFill)
            Blobs(circles: Self.canopyShine).fill(.white.opacity(mood == .normal ? 0.45 : 0.18))
            if mood == .hibernating {
                Blobs(circles: Self.snowCap).fill(.white)
                Blobs(circles: Self.snowShine).fill(Color(hex: 0xDDE6FF))
            }
            if stage >= 6 && mood == .normal { flowers(in: size) }
            if stage >= 7 && mood == .normal { fruits(in: size) }
            TreeFace(mood: mood, scale: face).offset(y: size.height * 0.1)
        }
        .frame(width: size.width, height: size.height)
    }

    /// 树冠：一团云朵状的圆（单位坐标，半径按宽度算）
    private static let canopyBlobs: [Blob] = [
        .init(0.50, 0.36, 0.28), .init(0.31, 0.30, 0.19), .init(0.69, 0.31, 0.19),
        .init(0.25, 0.56, 0.23), .init(0.75, 0.56, 0.23), .init(0.50, 0.62, 0.27),
        .init(0.13, 0.70, 0.13), .init(0.87, 0.70, 0.13)
    ]
    private static let canopyShine: [Blob] = [
        .init(0.33, 0.24, 0.075), .init(0.45, 0.17, 0.04), .init(0.20, 0.47, 0.035)
    ]
    private static let snowCap: [Blob] = [
        .init(0.50, 0.13, 0.17), .init(0.33, 0.19, 0.12), .init(0.67, 0.19, 0.12)
    ]
    private static let snowShine: [Blob] = [.init(0.44, 0.09, 0.05)]

    private func flowers(in size: CGSize) -> some View {
        let spots: [(CGFloat, CGFloat)] = [(0.30, 0.26), (0.70, 0.22), (0.18, 0.58), (0.84, 0.56), (0.56, 0.80), (0.40, 0.70)]
        return ZStack {
            ForEach(Array(spots.enumerated()), id: \.offset) { i, p in
                Blossom(petal: i % 2 == 0 ? Theme.pink : Color(hex: 0xFFB3DD), size: 18)
                    .rotationEffect(.degrees(Double(i) * 23))
                    .position(x: p.0 * size.width, y: p.1 * size.height)
            }
        }
    }

    private func fruits(in size: CGSize) -> some View {
        let spots: [(CGFloat, CGFloat)] = [(0.42, 0.30), (0.78, 0.42), (0.24, 0.76), (0.66, 0.70)]
        return ZStack {
            ForEach(Array(spots.enumerated()), id: \.offset) { _, p in
                Image(systemName: "star.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFE38A), Theme.gold], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Theme.gold.opacity(0.9), radius: 6)
                    .position(x: p.0 * size.width, y: p.1 * size.height)
            }
        }
    }
}

// MARK: - Face

/// 小树的脸：开心 / 口渴 / 打瞌睡 / 冬眠
struct TreeFace: View {
    var mood: TreeMood
    var scale: CGFloat = 1

    var body: some View {
        let ink = Color(hex: 0x23264F)
        VStack(spacing: 5 * scale) {
            HStack(spacing: 22 * scale) {
                eye(ink)
                eye(ink)
            }
            mouth(ink)
        }
        .overlay {
            HStack(spacing: 40 * scale) {
                Ellipse().fill(Theme.pink.opacity(mood == .normal ? 0.55 : 0.25))
                Ellipse().fill(Theme.pink.opacity(mood == .normal ? 0.55 : 0.25))
            }
            .frame(width: 70 * scale, height: 7 * scale)
            .offset(y: 4 * scale)
        }
    }

    @ViewBuilder
    private func eye(_ ink: Color) -> some View {
        switch mood {
        case .normal:
            Ellipse().fill(ink).frame(width: 9 * scale, height: 12 * scale)
                .overlay(alignment: .topTrailing) {
                    Circle().fill(.white).frame(width: 3.5 * scale, height: 3.5 * scale).offset(x: -1 * scale, y: 2 * scale)
                }
        case .thirsty:
            // 没精神：眼皮耷拉一半
            Ellipse().fill(ink).frame(width: 9 * scale, height: 7 * scale)
                .overlay(alignment: .top) { Rectangle().fill(ink).frame(width: 11 * scale, height: 2 * scale) }
        case .sleepy, .hibernating:
            SmileArc().stroke(ink, style: StrokeStyle(lineWidth: 2.4 * scale, lineCap: .round))
                .frame(width: 11 * scale, height: 4 * scale)
        }
    }

    @ViewBuilder
    private func mouth(_ ink: Color) -> some View {
        switch mood {
        case .normal:
            SmileArc().fill(Color(hex: 0xE2557F))
                .overlay(SmileArc().stroke(ink, style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round, lineJoin: .round)))
                .frame(width: 14 * scale, height: 6 * scale)
        case .thirsty:
            WavyLine().stroke(ink, style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round))
                .frame(width: 12 * scale, height: 3 * scale)
        case .sleepy, .hibernating:
            Ellipse().stroke(ink, lineWidth: 2 * scale).frame(width: 6 * scale, height: 5 * scale)
        }
    }
}

// MARK: - Shapes

struct Blob {
    let x: CGFloat, y: CGFloat, r: CGFloat
    init(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) { self.x = x; self.y = y; self.r = r }
}

/// 若干个圆合成的一团（树冠、云、雪）
struct Blobs: Shape {
    let circles: [Blob]
    func path(in rect: CGRect) -> Path {
        var p = Path()
        for c in circles {
            let r = c.r * rect.width
            p.addEllipse(in: CGRect(x: rect.minX + c.x * rect.width - r,
                                    y: rect.minY + c.y * rect.height - r,
                                    width: r * 2, height: r * 2))
        }
        return p
    }
}

/// 下宽上窄、底部带树根弧度的树干
struct TrunkShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.minX - w * 0.25, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.22, y: r.minY + h * 0.72),
                       control: CGPoint(x: r.minX + w * 0.18, y: r.maxY - 2))
        p.addLine(to: CGPoint(x: r.minX + w * 0.30, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + w * 0.70, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + w * 0.78, y: r.minY + h * 0.72))
        p.addQuadCurve(to: CGPoint(x: r.maxX + w * 0.25, y: r.maxY),
                       control: CGPoint(x: r.maxX - w * 0.18, y: r.maxY - 2))
        p.closeSubpath()
        return p
    }
}

/// 一片叶子（尖头椭圆 + 叶脉），默认叶尖朝右
struct Leaf: View {
    let fill: LinearGradient
    let vein: Color
    var body: some View {
        LeafShape().fill(fill)
            .overlay(Capsule().fill(vein.opacity(0.6)).frame(height: 1.6).padding(.horizontal, 5))
    }
}

struct LeafShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.45))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY), control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.45))
        p.closeSubpath()
        return p
    }
}

/// 嫩芽的弯曲茎
struct StemCurve: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: r.maxX + 6, y: r.midY))
        return p
    }
}

/// 向下弯的弧：微笑的嘴、闭着的眼睛
struct SmileArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY + r.height))
        p.closeSubpath()
        return p
    }
}

struct WavyLine: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.midY), control: CGPoint(x: r.minX + r.width * 0.25, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: r.minX + r.width * 0.75, y: r.maxY))
        return p
    }
}

/// 五瓣小花
struct Blossom: View {
    var petal: Color
    var size: CGFloat
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(petal).frame(width: size * 0.45, height: size * 0.45)
                    .offset(y: -size * 0.27)
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            Circle().fill(Theme.gold).frame(width: size * 0.32, height: size * 0.32)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Bunny

/// 大树阶段来做客的小兔子
struct BunnyView: View {
    var body: some View {
        let fur = Color(hex: 0xF1F3FF), shade = Color(hex: 0xC9CEF2), ink = Color(hex: 0x23264F)
        ZStack {
            // 耳朵
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule().fill(fur).frame(width: 11, height: 28)
                    .overlay(Capsule().fill(Color(hex: 0xFFB3D1)).frame(width: 5, height: 18).offset(y: 2))
                    .rotationEffect(.degrees(side * 10), anchor: .bottom)
                    .offset(x: side * 7, y: -24)
            }
            // 身体和尾巴
            Ellipse().fill(shade).frame(width: 40, height: 30).offset(y: 10)
            Ellipse().fill(fur).frame(width: 38, height: 28).offset(y: 9)
            Circle().fill(.white).frame(width: 12).offset(x: 19, y: 14)
            // 头
            Circle().fill(fur).frame(width: 32, height: 32).offset(y: -6)
            HStack(spacing: 9) {
                Circle().fill(ink).frame(width: 4.5)
                Circle().fill(ink).frame(width: 4.5)
            }
            .offset(y: -8)
            Ellipse().fill(Color(hex: 0xFF8FB8)).frame(width: 5, height: 3.5).offset(y: -3)
            HStack(spacing: 16) {
                Ellipse().fill(Theme.pink.opacity(0.4)).frame(width: 7, height: 4)
                Ellipse().fill(Theme.pink.opacity(0.4)).frame(width: 7, height: 4)
            }
            .offset(y: -2)
        }
        .frame(width: 48, height: 64)
    }
}
