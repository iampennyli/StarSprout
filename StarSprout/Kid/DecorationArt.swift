import SwiftUI

/// 装饰的矢量画法。插画专用色写在本文件里（同 TreeView / PlanetArt）。
///
/// - `DecorArt(id:)`：单件装饰的独立画像，用在商店卡片和星球场景（树顶 / 草地 / 天空）。
/// - `OrnamentArt`：挂在树冠上的装饰，按树冠尺寸绘制，由 TreeView 调用。
/// - `PlanetRing`：星环（默认粉色 / 金色 / 彩虹），分前后两半。
struct DecorArt: View {
    let id: String

    var body: some View {
        switch id {
        case "hat.star": StarTopper()
        case "hat.crown": Crown()
        case "hat.bird": Bird()
        case "ornament.lantern": Lantern(scale: 1.6)
        case "ornament.lights": LightsIcon()
        case "ground.mushroom": Mushroom()
        case "ground.swing": Swing()
        case "ground.house": Cottage()
        case "sky.moon": Moon()
        case "sky.satellite": Satellite()
        case "sky.rainbow": Rainbow(width: 70)
        case "ring.gold": RingIcon(style: .gold)
        case "ring.rainbow": RingIcon(style: .rainbow)
        default: Image(systemName: "questionmark").foregroundStyle(Theme.muted)
        }
    }

    /// 画像的自然尺寸，商店卡片据此缩放
    static func naturalSize(_ id: String) -> CGSize {
        switch id {
        case "hat.star": return CGSize(width: 40, height: 40)
        case "hat.crown": return CGSize(width: 46, height: 34)
        case "hat.bird": return CGSize(width: 44, height: 34)
        case "ornament.lantern": return CGSize(width: 32, height: 56)
        case "ornament.lights": return CGSize(width: 70, height: 40)
        case "ground.mushroom": return CGSize(width: 36, height: 36)
        case "ground.swing": return CGSize(width: 56, height: 54)
        case "ground.house": return CGSize(width: 60, height: 58)
        case "sky.moon": return CGSize(width: 52, height: 52)
        case "sky.satellite": return CGSize(width: 64, height: 34)
        case "sky.rainbow": return CGSize(width: 70, height: 38)
        default: return CGSize(width: 70, height: 30)
        }
    }
}

// MARK: - 树顶

private struct StarTopper: View {
    var body: some View {
        ZStack {
            Circle().fill(Theme.gold.opacity(0.35)).frame(width: 40, height: 40).blur(radius: 6)
            StarShape(points: 5, inner: 0.45)
                .fill(LinearGradient(colors: [Color(hex: 0xFFF1A8), Theme.gold], startPoint: .top, endPoint: .bottom))
                .overlay(StarShape(points: 5, inner: 0.45).stroke(Color(hex: 0xE0A21E), lineWidth: 1.5))
                .frame(width: 32, height: 32)
        }
        .frame(width: 40, height: 40)
    }
}

private struct Crown: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            CrownShape()
                .fill(LinearGradient(colors: [Color(hex: 0xFFE680), Color(hex: 0xF0A92A)], startPoint: .top, endPoint: .bottom))
                .overlay(CrownShape().stroke(Color(hex: 0xC98314), lineWidth: 1.5))
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xE89A22)).frame(width: 44, height: 8)
            HStack(spacing: 8) {
                Circle().fill(Theme.cyan).frame(width: 6)
                Circle().fill(Theme.pink).frame(width: 7)
                Circle().fill(Theme.cyan).frame(width: 6)
            }
            .padding(.bottom, 1)
        }
        .frame(width: 46, height: 34)
    }
}

private struct CrownShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.minX + w * 0.04, y: r.maxY - 4))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + h * 0.25))
        p.addLine(to: CGPoint(x: r.minX + w * 0.27, y: r.minY + h * 0.55))
        p.addLine(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.27, y: r.minY + h * 0.55))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + h * 0.25))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.04, y: r.maxY - 4))
        p.closeSubpath()
        return p
    }
}

private struct Bird: View {
    var body: some View {
        ZStack {
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0x8FD3FF), Color(hex: 0x3D8DE0)], startPoint: .top, endPoint: .bottom))
                .frame(width: 32, height: 24).offset(x: -2, y: 4)
            Ellipse().fill(Color(hex: 0xFFF4E0)).frame(width: 16, height: 12).offset(x: 4, y: 8)
            Ellipse().fill(Color(hex: 0x2F72C4)).frame(width: 16, height: 10).rotationEffect(.degrees(-20)).offset(x: -8, y: 3)
            Circle().fill(Color(hex: 0x23264F)).frame(width: 4).offset(x: 6, y: -1)
            Triangle().fill(Color(hex: 0xFFA23A)).frame(width: 8, height: 6).rotationEffect(.degrees(90)).offset(x: 16, y: 1)
            // 头顶一撮毛 + 音符
            Capsule().fill(Color(hex: 0x3D8DE0)).frame(width: 3, height: 8).rotationEffect(.degrees(-20)).offset(x: 0, y: -10)
            Image(systemName: "music.note").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.gold).offset(x: 18, y: -13)
        }
        .frame(width: 44, height: 34)
    }
}

// MARK: - 挂饰

/// 挂在树冠上的装饰，按树冠尺寸绘制
struct OrnamentArt: View {
    let id: String
    let size: CGSize

    var body: some View {
        switch id {
        case "ornament.lights": lights
        case "ornament.lantern":
            ZStack {
                lanternAt(x: 0.80, y: 0.70, scale: size.width / 140)
                lanternAt(x: 0.22, y: 0.76, scale: size.width / 170)
            }
        default: EmptyView()
        }
    }

    private var lights: some View {
        let w = size.width, h = size.height
        let curves: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: 0.14 * w, y: 0.40 * h), CGPoint(x: 0.5 * w, y: 0.62 * h), CGPoint(x: 0.86 * w, y: 0.40 * h)),
            (CGPoint(x: 0.10 * w, y: 0.66 * h), CGPoint(x: 0.5 * w, y: 0.90 * h), CGPoint(x: 0.90 * w, y: 0.66 * h)),
        ]
        let colors: [Color] = [Theme.gold, Theme.pink, Theme.cyan, Theme.lime, Color(hex: 0xFF8A5B)]
        let bulb = max(5, w * 0.045)
        return ZStack {
            ForEach(0..<curves.count, id: \.self) { ci in
                let (a, c, b) = curves[ci]
                Path { p in p.move(to: a); p.addQuadCurve(to: b, control: c) }
                    .stroke(Color(hex: 0x2E5E3E), lineWidth: 1.2)
                ForEach(0..<7, id: \.self) { i in
                    let t = CGFloat(i + 1) / 8
                    let pt = quad(a, c, b, t)
                    let color = colors[(i + ci * 2) % colors.count]
                    Circle().fill(color)
                        .frame(width: bulb, height: bulb)
                        .shadow(color: color.opacity(0.9), radius: 4)
                        .position(pt)
                }
            }
        }
        .frame(width: w, height: h)
    }

    private func lanternAt(x: CGFloat, y: CGFloat, scale: CGFloat) -> some View {
        Lantern(scale: scale)
            .position(x: x * size.width, y: y * size.height + 14 * scale)
    }

    private func quad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(x: u * u * a.x + 2 * u * t * c.x + t * t * b.x,
                       y: u * u * a.y + 2 * u * t * c.y + t * t * b.y)
    }
}

private struct Lantern: View {
    var scale: CGFloat = 1
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(hex: 0x6B3A1E)).frame(width: 1.2 * scale, height: 6 * scale)
            RoundedRectangle(cornerRadius: 2 * scale).fill(Theme.gold).frame(width: 9 * scale, height: 3 * scale)
            Ellipse()
                .fill(RadialGradient(colors: [Color(hex: 0xFF8A6A), Color(hex: 0xE23A3A)], center: .center, startRadius: 1, endRadius: 10 * scale))
                .overlay(Capsule().fill(Color(hex: 0xB82424).opacity(0.5)).frame(width: 1 * scale))
                .frame(width: 15 * scale, height: 13 * scale)
                .shadow(color: Color(hex: 0xFF5A4A).opacity(0.7), radius: 5 * scale)
            RoundedRectangle(cornerRadius: 2 * scale).fill(Theme.gold).frame(width: 9 * scale, height: 3 * scale)
            Rectangle().fill(Theme.gold).frame(width: 1.5 * scale, height: 6 * scale)
        }
    }
}

private struct LightsIcon: View {
    var body: some View {
        OrnamentArt(id: "ornament.lights", size: CGSize(width: 80, height: 50))
            .frame(width: 70, height: 40)
    }
}

// MARK: - 草地

private struct Mushroom: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0xFFF1DC)).frame(width: 12, height: 18)
            ZStack {
                HalfCircle().fill(LinearGradient(colors: [Color(hex: 0xFF6B6B), Color(hex: 0xD93636)], startPoint: .top, endPoint: .bottom))
                Circle().fill(.white).frame(width: 6).offset(x: -8, y: -2)
                Circle().fill(.white).frame(width: 5).offset(x: 7, y: -5)
                Circle().fill(.white).frame(width: 4).offset(x: 1, y: 3)
            }
            .frame(width: 36, height: 20)
            .padding(.bottom, 14)
        }
        .frame(width: 36, height: 36)
    }
}

private struct Swing: View {
    var body: some View {
        let wood = Color(hex: 0xB07A4F)
        ZStack {
            // A 字架
            Capsule().fill(wood).frame(width: 4, height: 54).rotationEffect(.degrees(12)).offset(x: -22)
            Capsule().fill(wood).frame(width: 4, height: 54).rotationEffect(.degrees(-12)).offset(x: 22)
            Capsule().fill(Color(hex: 0x8A5A36)).frame(width: 54, height: 5).offset(y: -25)
            // 绳子和座板
            Rectangle().fill(Color(hex: 0xF3E3C3)).frame(width: 1.5, height: 30).offset(x: -8, y: -8)
            Rectangle().fill(Color(hex: 0xF3E3C3)).frame(width: 1.5, height: 30).offset(x: 8, y: -8)
            RoundedRectangle(cornerRadius: 2).fill(Theme.pink).frame(width: 22, height: 5).offset(y: 8)
        }
        .frame(width: 56, height: 54)
    }
}

private struct Cottage: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [Color(hex: 0xE2A46C), Color(hex: 0xB9774A)], startPoint: .top, endPoint: .bottom))
                .frame(width: 46, height: 32)
            // 门
            UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6).fill(Color(hex: 0x6B3A1E))
                .frame(width: 11, height: 18).offset(x: -9)
            // 亮着灯的窗
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xFFE38A))
                .frame(width: 11, height: 10)
                .shadow(color: Theme.gold.opacity(0.8), radius: 4)
                .offset(x: 10, y: -12)
            // 屋顶 + 烟囱
            Rectangle().fill(Color(hex: 0x8A5A36)).frame(width: 6, height: 12).offset(x: 13, y: -44)
            Triangle().fill(LinearGradient(colors: [Color(hex: 0xFF7A6B), Color(hex: 0xD9483E)], startPoint: .top, endPoint: .bottom))
                .frame(width: 60, height: 28).offset(y: -30)
        }
        .frame(width: 60, height: 58)
    }
}

// MARK: - 天空

private struct Moon: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xFFF1A8).opacity(0.25)).frame(width: 52, height: 52).blur(radius: 6)
            Circle()
                .fill(LinearGradient(colors: [Color(hex: 0xFFF6C8), Color(hex: 0xFFD45C)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 40, height: 40)
                .mask {
                    Rectangle().overlay(Circle().frame(width: 34, height: 34).offset(x: 12, y: -8).blendMode(.destinationOut))
                        .compositingGroup()
                }
        }
        .frame(width: 52, height: 52)
    }
}

private struct Satellite: View {
    var body: some View {
        ZStack {
            HStack(spacing: 26) {
                panel
                panel
            }
            Rectangle().fill(Color(hex: 0xC9CDF0)).frame(width: 46, height: 2)
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [Color(hex: 0xF1F3FF), Color(hex: 0xB9BEE8)], startPoint: .top, endPoint: .bottom))
                .frame(width: 18, height: 16)
            Circle().fill(Theme.pink).frame(width: 5).offset(x: 0, y: -12).shadow(color: Theme.pink, radius: 3)
            Rectangle().fill(Color(hex: 0xC9CDF0)).frame(width: 1.5, height: 6).offset(y: -9)
        }
        .frame(width: 64, height: 34)
    }

    private var panel: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(LinearGradient(colors: [Color(hex: 0x5BA8FF), Color(hex: 0x2E5FC4)], startPoint: .top, endPoint: .bottom))
            .overlay(Rectangle().fill(.white.opacity(0.4)).frame(width: 1))
            .frame(width: 18, height: 12)
    }
}

/// 彩虹：一组同心半圆弧
struct Rainbow: View {
    var width: CGFloat
    private static let colors: [Color] = [
        Color(hex: 0xFF6B6B), Color(hex: 0xFFA94D), Color(hex: 0xFFE066),
        Color(hex: 0x8CE99A), Color(hex: 0x66D9E8), Color(hex: 0x748FFC), Color(hex: 0xC490F5),
    ]
    var body: some View {
        let band = width * 0.045
        ZStack(alignment: .bottom) {
            ForEach(0..<Self.colors.count, id: \.self) { i in
                let d = width - CGFloat(i) * band * 2
                Circle().trim(from: 0.5, to: 1)
                    .stroke(Self.colors[i], lineWidth: band)
                    .frame(width: d, height: d)
                    .offset(y: d / 2)
            }
        }
        .frame(width: width, height: width / 2 + band, alignment: .bottom)
        .clipped()
    }
}

// MARK: - 星环

enum RingStyle { case standard, gold, rainbow }

/// 星环。`back` 画后半圈（压在星球后面），否则画前半圈
struct PlanetRing: View {
    var style: RingStyle
    var back: Bool

    var body: some View {
        Ellipse().trim(from: back ? 0.5 : 0, to: back ? 1 : 0.5)
            .stroke(gradient, lineWidth: style == .standard ? 4 : 6)
            .opacity(back ? 0.55 : 1)
    }

    private var gradient: LinearGradient {
        switch style {
        case .standard:
            return LinearGradient(colors: [Theme.pink.opacity(0.3), Theme.pink.opacity(0.8), Theme.pink.opacity(0.3)],
                                  startPoint: .leading, endPoint: .trailing)
        case .gold:
            return LinearGradient(colors: [Color(hex: 0xC98314), Color(hex: 0xFFF1A8), Theme.gold, Color(hex: 0xC98314)],
                                  startPoint: .leading, endPoint: .trailing)
        case .rainbow:
            return LinearGradient(colors: [Color(hex: 0xFF6B6B), Color(hex: 0xFFE066), Color(hex: 0x8CE99A),
                                           Color(hex: 0x66D9E8), Color(hex: 0xC490F5)],
                                  startPoint: .leading, endPoint: .trailing)
        }
    }

    static func style(for id: String?) -> RingStyle {
        switch id {
        case "ring.gold": return .gold
        case "ring.rainbow": return .rainbow
        default: return .standard
        }
    }
}

private struct RingIcon: View {
    var style: RingStyle
    var body: some View {
        ZStack {
            PlanetRing(style: style, back: true).frame(width: 66, height: 18)
            Circle().fill(RadialGradient(colors: [Color(hex: 0x8C95F5), Color(hex: 0x4C55B8)], center: UnitPoint(x: 0.35, y: 0.3),
                                         startRadius: 1, endRadius: 22))
                .frame(width: 30, height: 30)
            PlanetRing(style: style, back: false).frame(width: 66, height: 18)
        }
        .frame(width: 70, height: 34)
    }
}

// MARK: - Shapes

struct StarShape: Shape {
    var points: Int
    var inner: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        let outerR = min(r.width, r.height) / 2
        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let rad = i.isMultiple(of: 2) ? outerR : outerR * inner
            let pt = CGPoint(x: c.x + rad * CGFloat(cos(angle)), y: c.y + rad * CGFloat(sin(angle)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct HalfCircle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: r.midX, y: r.maxY), radius: r.width / 2,
                 startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        p.closeSubpath()
        return p
    }
}
