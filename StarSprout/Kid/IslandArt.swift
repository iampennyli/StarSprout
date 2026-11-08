import SwiftUI

/// 2.5D 漂浮小岛：从斜上方约 30° 看过去的一块圆形小岛——草地顶面、泥土侧面、岩石底锥，浮在星空里。
///
/// 顶面上的东西（小树、装饰、小兔子、草丛）都按「极坐标」摆放：半径 r（0 = 圆心，1 = 边缘）和角度 φ。
/// 拖动小岛时整体转一个角度 `angle`：所有物体绕圆心转，越靠前（屏幕下方）的越大、越晚画，自然形成遮挡。
/// 小树、小兔子是可交互的，由调用方传进来；其余都在这里画。插画专用色写在本文件里。
enum Island {
    /// 场景画布（星球页、商店预览、首页缩略都按这个尺寸画，再整体缩放）
    static let canvas = CGSize(width: 380, height: 430)
    static let center = CGPoint(x: 190, y: 286)
    /// 顶面椭圆的半长轴 / 半短轴（短轴约为长轴的 1/3，就是 30° 俯视的观感）
    static let a: CGFloat = 146
    static let b: CGFloat = 48
    /// 侧面泥土层厚度、底锥深度
    static let thickness: CGFloat = 30
    static let coneDepth: CGFloat = 92
    /// 小树在小岛上的缩放
    static let treeScale: CGFloat = 0.86

    static func point(r: CGFloat, phi: Double, angle: Double) -> (CGPoint, Double) {
        let t = phi + angle
        let p = CGPoint(x: center.x + r * a * CGFloat(cos(t)), y: center.y + r * b * CGFloat(sin(t)))
        return (p, Double(r) * sin(t))
    }

    /// 顶面颜色：小树越大草地越茂盛；第 6 阶段「整颗星球变色」变成开满小花的青绿草地
    static func topColors(stage: Int) -> (light: Color, dark: Color, lip: Color) {
        switch stage {
        case ...2: return (Color(hex: 0xC8E59A), Color(hex: 0x9CCB6A), Color(hex: 0x7FAE4E))
        case 3...5: return (Color(hex: 0x9BEBA6), Color(hex: 0x52C27A), Color(hex: 0x3A9E5E))
        default: return (Color(hex: 0x9AF2D6), Color(hex: 0x3FC2A0), Color(hex: 0x2A9C82))
        }
    }

    /// 每个装饰位置在顶面上的位置（r, φ）。φ = π/2 是正前方
    static let slotSpots: [DecorSlot: (r: CGFloat, phi: Double)] = [
        .ground: (0.66, 2.55),      // 左前
        .landmark: (0.70, -0.75),   // 右后
        .pet: (0.58, 0.95),         // 右前
    ]
    static let bunnySpot: (r: CGFloat, phi: Double) = (0.70, 0.15)
}

/// 小岛场景
struct IslandScene<Tree: View, Bunny: View>: View {
    var stage: Int
    var decor: [DecorSlot: String]
    var angle: Double
    var showBunny: Bool
    @ViewBuilder var tree: () -> Tree
    @ViewBuilder var bunny: () -> Bunny

    var body: some View {
        let ring = PlanetRing.style(for: decor[.ring])
        let ringCenter = CGPoint(x: Island.center.x, y: Island.center.y + Island.thickness * 0.7)
        ZStack(alignment: .topLeading) {
            // 小岛底下的光晕
            Ellipse().fill(Island.topColors(stage: stage).dark.opacity(0.22))
                .frame(width: 300, height: 140).blur(radius: 30)
                .position(x: Island.center.x, y: Island.center.y + 40)
            if decor[.sky] == "sky.rainbow" {
                Rainbow(width: 330).opacity(0.7)
                    .position(x: Island.center.x, y: Island.center.y - 104)
            }
            PlanetRing(style: ring, back: true)
                .frame(width: 372, height: 112).position(ringCenter)
            FloatingRocks()
            IslandBody(stage: stage, angle: angle)
            PlanetRing(style: ring, back: false)
                .frame(width: 372, height: 112).position(ringCenter)
            surfaceItems
            skyItem
        }
        .frame(width: Island.canvas.width, height: Island.canvas.height)
    }

    // MARK: 顶面物体（按深度排序）

    private struct Placed: Identifiable {
        let id: String
        let r: CGFloat
        let phi: Double
        let size: CGSize
        let shadow: CGFloat
        let view: AnyView
    }

    private var placed: [Placed] {
        var list: [Placed] = []
        // 小树在圆心
        list.append(Placed(id: "tree", r: 0, phi: 0, size: CGSize(width: 240, height: 260),
                           shadow: stage >= 4 ? 120 : stage == 3 ? 70 : 40, view: AnyView(
                            tree().scaleEffect(Island.treeScale, anchor: .bottom))))
        // 草丛、小石头、小花：让顶面有质感，转动时能看出在转
        for (i, tuft) in IslandDetails.tufts.enumerated() {
            list.append(Placed(id: "tuft\(i)", r: tuft.r, phi: tuft.phi, size: CGSize(width: 20, height: 14), shadow: 0,
                               view: AnyView(GrassTuft(color: Island.topColors(stage: stage).lip))))
        }
        for (i, s) in IslandDetails.stones.enumerated() {
            list.append(Placed(id: "stone\(i)", r: s.r, phi: s.phi, size: CGSize(width: 18, height: 12), shadow: 10,
                               view: AnyView(Pebble())))
        }
        if stage >= 4 {
            for (i, f) in IslandDetails.flowers.prefix(stage >= 6 ? 6 : 3).enumerated() {
                list.append(Placed(id: "flower\(i)", r: f.r, phi: f.phi, size: CGSize(width: 16, height: 22), shadow: 0,
                                   view: AnyView(StemFlower(color: [Theme.pink, Theme.gold, Color(hex: 0xB59BFF), .white][i % 4]))))
            }
        }
        // 装饰
        for slot in [DecorSlot.ground, .landmark, .pet] {
            guard let id = decor[slot], let spot = Island.slotSpots[slot] else { continue }
            let n = DecorArt.naturalSize(id)
            let flat = id == "ground.pond"
            list.append(Placed(id: "decor-\(slot.rawValue)", r: spot.r, phi: spot.phi, size: n,
                               shadow: flat ? 0 : n.width * 0.8, view: AnyView(DecorArt(id: id).modifier(Bob(enabled: slot == .pet)))))
        }
        if showBunny {
            list.append(Placed(id: "bunny", r: Island.bunnySpot.r, phi: Island.bunnySpot.phi, size: CGSize(width: 48, height: 64),
                               shadow: 36, view: AnyView(bunny())))
        }
        return list
    }

    private struct Drawn: Identifiable {
        let p: Placed
        let pt: CGPoint
        let depth: Double
        var id: String { p.id }
    }

    private var surfaceItems: some View {
        let items = placed.map { p -> Drawn in
            let (pt, depth) = Island.point(r: p.r, phi: p.phi, angle: angle)
            return Drawn(p: p, pt: pt, depth: depth)
        }
        .sorted { $0.depth < $1.depth }
        return ZStack(alignment: .topLeading) {
            ForEach(items) { item in
                let p = item.p, pt = item.pt, depth = item.depth
                // 越靠前越大一点
                let s = 0.92 + 0.14 * (depth + 1) / 2
                ZStack(alignment: .topLeading) {
                    if p.shadow > 0 {
                        Ellipse().fill(Color(hex: 0x14301F).opacity(0.28))
                            .frame(width: p.shadow * s, height: p.shadow * s * 0.32)
                            .blur(radius: 2)
                            .position(x: pt.x, y: pt.y)
                    }
                    p.view
                        .frame(width: p.size.width, height: p.size.height, alignment: .bottom)
                        .scaleEffect(p.id == "tree" ? 1 : s, anchor: .bottom)
                        .position(x: pt.x, y: pt.y - p.size.height / 2 + 3)
                }
            }
        }
        .frame(width: Island.canvas.width, height: Island.canvas.height, alignment: .topLeading)
    }

    // MARK: 天空

    @ViewBuilder
    private var skyItem: some View {
        switch decor[.sky] {
        case "sky.moon": DecorArt(id: "sky.moon").position(x: 330, y: 62)
        case "sky.cloud": DecorArt(id: "sky.cloud").modifier(Drift()).position(x: 310, y: 74)
        case "sky.satellite": DecorArt(id: "sky.satellite").rotationEffect(.degrees(-14)).modifier(Bob(enabled: true)).position(x: 318, y: 70)
        case "sky.meteor": DecorArt(id: "sky.meteor").position(x: 300, y: 60)
        case "sky.balloon": DecorArt(id: "sky.balloon").modifier(Bob(enabled: true)).position(x: 326, y: 92)
        default: EmptyView()
        }
    }
}

extension IslandScene where Tree == TreeView, Bunny == BunnyView {
    /// 不可交互的版本（商店预览、首页缩略、美术检查页）
    init(stage: Int, mood: TreeMood, decor: [DecorSlot: String], angle: Double = 0) {
        self.init(stage: stage, decor: decor, angle: angle, showBunny: stage >= 5,
                  tree: { TreeView(stage: stage, mood: mood, hat: decor[.hat], ornament: stage >= 3 ? decor[.ornament] : nil) },
                  bunny: { BunnyView() })
    }
}

// MARK: - 小岛本体

/// 顶面 + 侧面 + 底锥 + 侧面上的点缀（侧面点缀也跟着角度转）
struct IslandBody: View {
    var stage: Int
    var angle: Double

    var body: some View {
        let c = Island.center, a = Island.a, b = Island.b, t = Island.thickness
        let top = Island.topColors(stage: stage)
        ZStack(alignment: .topLeading) {
            // 底锥（岩石）
            ConeShape(center: c, a: a, b: b, top: t, depth: Island.coneDepth)
                .fill(LinearGradient(colors: [Color(hex: 0x8A5C3C), Color(hex: 0x5B4170), Color(hex: 0x2E2656)],
                                     startPoint: .top, endPoint: .bottom))
            // 岩层纹理
            ConeShape(center: c, a: a, b: b, top: t, depth: Island.coneDepth)
                .fill(.clear)
                .overlay {
                    ZStack(alignment: .topLeading) {
                        ForEach(0..<3, id: \.self) { i in
                            let y = c.y + t + 18 + CGFloat(i) * 22
                            let w = a * (1.7 - CGFloat(i) * 0.45)
                            Ellipse().stroke(Color.white.opacity(0.08), lineWidth: 3)
                                .frame(width: w, height: w * 0.18)
                                .position(x: c.x + 4, y: y)
                        }
                    }
                }
                .clipShape(ConeShape(center: c, a: a, b: b, top: t, depth: Island.coneDepth))
            // 侧面（泥土）
            SideBand(center: c, a: a, b: b, thickness: t)
                .fill(LinearGradient(colors: [Color(hex: 0xB07A4F), Color(hex: 0x8A5C3C)], startPoint: .top, endPoint: .bottom))
            sideFeatures
            // 草地边缘（比顶面稍低一点、颜色深一点，像草皮的厚度）
            Ellipse().fill(top.lip)
                .frame(width: a * 2, height: b * 2).position(x: c.x, y: c.y + 6)
            // 顶面
            Ellipse().fill(RadialGradient(colors: [top.light, top.dark], center: UnitPoint(x: 0.4, y: 0.3),
                                          startRadius: 10, endRadius: a * 1.1))
                .frame(width: a * 2, height: b * 2).position(c)
            // 顶面高光
            Ellipse().fill(.white.opacity(0.14))
                .frame(width: a * 1.1, height: b * 0.7).position(x: c.x - a * 0.22, y: c.y - b * 0.42)
        }
        .frame(width: Island.canvas.width, height: Island.canvas.height, alignment: .topLeading)
    }

    /// 侧面上的小石头、树根、水晶（第 6 阶段以后发光），只画转到前面的
    private var sideFeatures: some View {
        let c = Island.center
        return ZStack(alignment: .topLeading) {
            ForEach(Array(IslandDetails.side.enumerated()), id: \.offset) { i, f in
                let t = f.phi + angle
                let s = sin(t)
                if s > 0.15 {
                    let x = c.x + Island.a * 0.97 * CGFloat(cos(t))
                    let y = c.y + Island.b * CGFloat(s) + Island.thickness * f.h
                    Group {
                        switch f.kind {
                        case 0:
                            Ellipse().fill(Color(hex: 0x6E4A30)).frame(width: 12, height: 7)
                        case 1:
                            Capsule().fill(Color(hex: 0x7A5236)).frame(width: 3, height: 14).rotationEffect(.degrees(Double(i * 17 % 30) - 15))
                        default:
                            Crystal(glow: stage >= 6)
                        }
                    }
                    .scaleEffect(0.6 + 0.4 * CGFloat(s))
                    .position(x: x, y: y)
                }
            }
        }
    }
}

/// 侧面：顶面椭圆下半圈往下挤出 thickness 的一圈带子
private struct SideBand: Shape {
    let center: CGPoint, a: CGFloat, b: CGFloat, thickness: CGFloat
    func path(in _: CGRect) -> Path {
        var p = Path()
        let steps = 48
        p.move(to: CGPoint(x: center.x - a, y: center.y))
        for i in 0...steps {   // 下沿：从左往右，沿下移后的椭圆下半圈
            let t = Double.pi - Double.pi * Double(i) / Double(steps)
            p.addLine(to: CGPoint(x: center.x + a * CGFloat(cos(t)), y: center.y + thickness + b * CGFloat(sin(t))))
        }
        for i in 0...steps {   // 上沿：从右往左，沿顶面椭圆下半圈
            let t = Double.pi * Double(i) / Double(steps)
            p.addLine(to: CGPoint(x: center.x + a * CGFloat(cos(t)), y: center.y + b * CGFloat(sin(t))))
        }
        p.closeSubpath()
        return p
    }
}

/// 底锥：从侧面下沿收拢到底部尖端，边缘带一点起伏，像掰下来的一块岩石
private struct ConeShape: Shape {
    let center: CGPoint, a: CGFloat, b: CGFloat, top: CGFloat, depth: CGFloat
    func path(in _: CGRect) -> Path {
        var p = Path()
        let steps = 36
        let y0 = center.y + top
        p.move(to: CGPoint(x: center.x - a, y: y0))
        for i in 0...steps {
            let t = Double.pi - Double.pi * Double(i) / Double(steps)
            p.addLine(to: CGPoint(x: center.x + a * CGFloat(cos(t)), y: y0 + b * CGFloat(sin(t))))
        }
        // 右侧向下收到尖端，再从左侧回来，带几个凸起
        let tip = CGPoint(x: center.x + 10, y: y0 + b + depth)
        p.addCurve(to: CGPoint(x: center.x + a * 0.45, y: y0 + b + depth * 0.45),
                   control1: CGPoint(x: center.x + a * 0.95, y: y0 + b * 0.9),
                   control2: CGPoint(x: center.x + a * 0.62, y: y0 + b + depth * 0.25))
        p.addCurve(to: tip,
                   control1: CGPoint(x: center.x + a * 0.30, y: y0 + b + depth * 0.62),
                   control2: CGPoint(x: center.x + 26, y: y0 + b + depth * 0.85))
        p.addCurve(to: CGPoint(x: center.x - a * 0.5, y: y0 + b + depth * 0.4),
                   control1: CGPoint(x: center.x - 8, y: y0 + b + depth * 0.82),
                   control2: CGPoint(x: center.x - a * 0.32, y: y0 + b + depth * 0.6))
        p.addCurve(to: CGPoint(x: center.x - a, y: y0),
                   control1: CGPoint(x: center.x - a * 0.7, y: y0 + b + depth * 0.2),
                   control2: CGPoint(x: center.x - a * 0.98, y: y0 + b * 0.8))
        p.closeSubpath()
        return p
    }
}

/// 小岛周围漂浮的碎石
private struct FloatingRocks: View {
    @State private var up = false
    var body: some View {
        let c = Island.center
        ZStack(alignment: .topLeading) {
            rock(w: 22).position(x: c.x - Island.a - 6, y: c.y + 70).offset(y: up ? -5 : 3)
            rock(w: 14).position(x: c.x + Island.a + 10, y: c.y + 92).offset(y: up ? 4 : -4)
            rock(w: 10).position(x: c.x - 40, y: c.y + Island.thickness + Island.b + Island.coneDepth + 14).offset(y: up ? -3 : 3)
        }
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: up)
        .onAppear { up = true }
    }

    private func rock(w: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x5B4170)).frame(width: w, height: w * 0.75)
            Ellipse().fill(Color(hex: 0x8FD08F)).frame(width: w * 0.8, height: w * 0.3).offset(y: -w * 0.25)
        }
    }
}

// MARK: - 顶面小物件

enum IslandDetails {
    static let tufts: [(r: CGFloat, phi: Double)] = [
        (0.82, 0.4), (0.9, 1.9), (0.78, 3.4), (0.86, 4.4), (0.55, 5.3), (0.9, 2.9), (0.45, 1.3), (0.88, 5.9),
    ]
    static let stones: [(r: CGFloat, phi: Double)] = [(0.85, 1.25), (0.8, 3.9)]
    static let flowers: [(r: CGFloat, phi: Double)] = [(0.5, 2.0), (0.76, 0.65), (0.62, 4.0), (0.85, 2.35), (0.4, 5.6), (0.72, 1.6)]
    /// 侧面点缀：角度、在侧面上的高度（0 = 顶边，1 = 底边）、种类（0 石头 1 树根 2 水晶）
    static let side: [(phi: Double, h: CGFloat, kind: Int)] = [
        (0.3, 0.5, 0), (0.9, 0.35, 1), (1.4, 0.6, 2), (1.9, 0.45, 0), (2.4, 0.3, 1), (2.8, 0.55, 2),
        (3.5, 0.5, 0), (4.2, 0.4, 2), (4.9, 0.5, 1), (5.6, 0.45, 0),
    ]
}

private struct GrassTuft: View {
    var color: Color
    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule().fill(color).frame(width: 3, height: 10).rotationEffect(.degrees(-20), anchor: .bottom).offset(x: -3)
            Capsule().fill(color).frame(width: 3, height: 13)
            Capsule().fill(color).frame(width: 3, height: 9).rotationEffect(.degrees(22), anchor: .bottom).offset(x: 3)
        }
        .frame(width: 20, height: 14, alignment: .bottom)
    }
}

private struct Pebble: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x9A8FB8)).frame(width: 16, height: 10)
            Ellipse().fill(.white.opacity(0.35)).frame(width: 6, height: 3).offset(x: -3, y: -2)
        }
        .frame(width: 18, height: 12)
    }
}

private struct StemFlower: View {
    var color: Color
    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule().fill(Color(hex: 0x3FA866)).frame(width: 2.5, height: 12)
            Blossom(petal: color, size: 13).padding(.bottom, 9)
        }
        .frame(width: 16, height: 22, alignment: .bottom)
    }
}

private struct Crystal: View {
    var glow: Bool
    var body: some View {
        ZStack {
            if glow { Circle().fill(Theme.cyan.opacity(0.35)).frame(width: 18).blur(radius: 4) }
            Diamond().fill(LinearGradient(colors: [Color(hex: 0xC8F6FF), glow ? Theme.cyan : Color(hex: 0x9FB4E8)],
                                          startPoint: .top, endPoint: .bottom))
                .frame(width: 8, height: 13)
        }
    }
}

private struct Diamond: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: - 小动效

/// 上下轻轻浮动（伙伴、热气球、卫星）
struct Bob: ViewModifier {
    var enabled: Bool
    @State private var up = false
    func body(content: Content) -> some View {
        content
            .offset(y: enabled && up ? -4 : 0)
            .animation(enabled ? .easeInOut(duration: 1.6).repeatForever(autoreverses: true) : nil, value: up)
            .onAppear { if enabled { up = true } }
    }
}

/// 云朵左右慢慢飘
private struct Drift: ViewModifier {
    @State private var right = false
    func body(content: Content) -> some View {
        content
            .offset(x: right ? 10 : -10)
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: right)
            .onAppear { right = true }
    }
}

/// 缩放到任意尺寸的不可交互小岛（商店预览、首页缩略）
struct IslandThumbnail: View {
    let stage: Int
    let mood: TreeMood
    let decor: [DecorSlot: String]
    var angle: Double = 0

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / Island.canvas.width, geo.size.height / Island.canvas.height)
            IslandScene(stage: stage, mood: mood, decor: decor, angle: angle)
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
