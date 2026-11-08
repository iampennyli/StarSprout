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
        case "ring.ice": RingIcon(style: .ice)
        case "hat.bow": Bow()
        case "hat.santa": SantaHat()
        case "ornament.chime":
            OrnamentArt(id: "ornament.chime.icon", size: CGSize(width: 70, height: 56)).frame(width: 70, height: 56)
        case "ornament.stars":
            OrnamentArt(id: id, size: CGSize(width: 90, height: 60)).frame(width: 70, height: 56)
        case "ground.flowers": FlowerBush()
        case "ground.pumpkin": Pumpkin()
        case "ground.pond": Pond()
        case "landmark.tent": Tent()
        case "landmark.windmill": Windmill()
        case "landmark.lighthouse": Lighthouse()
        case "landmark.rocket": Rocket()
        case "pet.duck": Duck()
        case "pet.cat": Cat()
        case "pet.penguin": Penguin()
        case "sky.cloud": Cloud()
        case "sky.meteor": Meteors()
        case "sky.balloon": Balloon()
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
        case "hat.bow": return CGSize(width: 42, height: 26)
        case "hat.santa": return CGSize(width: 40, height: 40)
        case "ornament.chime", "ornament.stars": return CGSize(width: 70, height: 56)
        case "ground.flowers": return CGSize(width: 46, height: 30)
        case "ground.pumpkin": return CGSize(width: 40, height: 34)
        case "ground.pond": return CGSize(width: 64, height: 26)
        case "landmark.tent": return CGSize(width: 58, height: 48)
        case "landmark.windmill": return CGSize(width: 62, height: 86)
        case "landmark.lighthouse": return CGSize(width: 36, height: 92)
        case "landmark.rocket": return CGSize(width: 40, height: 84)
        case "pet.duck": return CGSize(width: 36, height: 32)
        case "pet.cat": return CGSize(width: 40, height: 40)
        case "pet.penguin": return CGSize(width: 32, height: 42)
        case "sky.cloud": return CGSize(width: 72, height: 36)
        case "sky.meteor": return CGSize(width: 90, height: 56)
        case "sky.balloon": return CGSize(width: 46, height: 66)
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
        case "ornament.chime":
            chime(x: 0.76, y: 0.72, scale: size.width / 130)
        case "ornament.chime.icon":
            chime(x: 0.5, y: 0.08, scale: 1.4)
        case "ornament.stars":
            ZStack {
                ForEach(Array([(0.22, 0.62, 18.0), (0.42, 0.78, 26.0), (0.62, 0.74, 14.0), (0.82, 0.60, 22.0)].enumerated()), id: \.offset) { _, s in
                    let k = size.width / 160
                    VStack(spacing: 0) {
                        Rectangle().fill(Color(hex: 0xE8D9A8)).frame(width: 1, height: s.2 * k)
                        StarShape(points: 5, inner: 0.45).fill(Theme.gold)
                            .frame(width: 13 * k, height: 13 * k)
                            .shadow(color: Theme.gold.opacity(0.9), radius: 4 * k)
                    }
                    .position(x: s.0 * size.width, y: s.1 * size.height + (s.2 * k) / 2)
                }
            }
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

    private func chime(x: CGFloat, y: CGFloat, scale k: CGFloat) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(hex: 0x6B3A1E)).frame(width: 1.2 * k, height: 8 * k)
            Capsule().fill(Color(hex: 0xC9CDF0)).frame(width: 24 * k, height: 3 * k)
            HStack(alignment: .top, spacing: 3 * k) {
                ForEach([14.0, 20, 16, 22], id: \.self) { h in
                    Capsule().fill(LinearGradient(colors: [Color(hex: 0xEAF6FF), Color(hex: 0x9FD8F0)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 3 * k, height: h * k)
                }
            }
            Circle().fill(Theme.pink).frame(width: 5 * k).padding(.top, 2 * k)
        }
        .position(x: x * size.width, y: y * size.height + 22 * k)
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

enum RingStyle { case standard, gold, rainbow, ice }

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
        case .ice:
            return LinearGradient(colors: [Color(hex: 0x9FE7FF).opacity(0.6), .white, Color(hex: 0x7CD6F5), .white, Color(hex: 0x9FE7FF).opacity(0.6)],
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
        case "ring.ice": return .ice
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

// MARK: - 新增装饰

private struct Bow: View {
    var body: some View {
        let pink = LinearGradient(colors: [Color(hex: 0xFFA6D6), Theme.pink], startPoint: .top, endPoint: .bottom)
        ZStack {
            Ellipse().fill(pink).frame(width: 20, height: 16).rotationEffect(.degrees(-18)).offset(x: -11, y: -2)
            Ellipse().fill(pink).frame(width: 20, height: 16).rotationEffect(.degrees(18)).offset(x: 11, y: -2)
            Capsule().fill(Theme.pink).frame(width: 5, height: 12).rotationEffect(.degrees(20)).offset(x: -5, y: 9)
            Capsule().fill(Theme.pink).frame(width: 5, height: 12).rotationEffect(.degrees(-20)).offset(x: 5, y: 9)
            Circle().fill(Color(hex: 0xE2559F)).frame(width: 9)
        }
        .frame(width: 42, height: 26)
    }
}

private struct SantaHat: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            SantaShape().fill(LinearGradient(colors: [Color(hex: 0xFF5A5A), Color(hex: 0xC92A2A)], startPoint: .top, endPoint: .bottom))
                .frame(width: 34, height: 32).padding(.bottom, 6)
            Capsule().fill(.white).frame(width: 38, height: 9)
            Circle().fill(.white).frame(width: 9).offset(x: 17, y: -26)
        }
        .frame(width: 40, height: 40)
    }
}

private struct SantaShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.1), control: CGPoint(x: r.minX + r.width * 0.2, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - r.width * 0.05, y: r.maxY), control: CGPoint(x: r.maxX - r.width * 0.15, y: r.midY))
        p.closeSubpath()
        return p
    }
}

private struct FlowerBush: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Blobs(circles: [.init(0.3, 0.6, 0.22), .init(0.55, 0.5, 0.25), .init(0.78, 0.62, 0.2)])
                .fill(LinearGradient(colors: [Color(hex: 0x7EDC95), Color(hex: 0x3FA866)], startPoint: .top, endPoint: .bottom))
                .frame(width: 46, height: 30)
            Blossom(petal: Theme.pink, size: 13).offset(x: -12, y: -14)
            Blossom(petal: Theme.gold, size: 12).offset(x: 4, y: -19)
            Blossom(petal: Color(hex: 0xB59BFF), size: 12).offset(x: 15, y: -10)
            Blossom(petal: .white, size: 10).offset(x: -2, y: -6)
        }
        .frame(width: 46, height: 30)
    }
}

private struct Pumpkin: View {
    var body: some View {
        let orange = LinearGradient(colors: [Color(hex: 0xFFB45C), Color(hex: 0xE8771F)], startPoint: .top, endPoint: .bottom)
        ZStack(alignment: .bottom) {
            Ellipse().fill(orange).frame(width: 20, height: 26).offset(x: -10)
            Ellipse().fill(orange).frame(width: 20, height: 26).offset(x: 10)
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0xFFC27A), Color(hex: 0xF08A2C)], startPoint: .top, endPoint: .bottom))
                .frame(width: 22, height: 28)
            Capsule().fill(Color(hex: 0x5E8C3A)).frame(width: 4, height: 9).rotationEffect(.degrees(15)).offset(x: 1, y: -24)
            LeafShape().fill(Color(hex: 0x6ECF7E)).frame(width: 12, height: 6).offset(x: 8, y: -27)
        }
        .frame(width: 40, height: 34)
    }
}

private struct Pond: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x8A6A4A)).frame(width: 64, height: 24)
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0x9BE7FF), Color(hex: 0x3BA7D9)], startPoint: .top, endPoint: .bottom))
                .frame(width: 56, height: 18)
            Ellipse().fill(.white.opacity(0.5)).frame(width: 14, height: 3).offset(x: -10, y: -3)
            Ellipse().fill(Color(hex: 0x5ED488)).frame(width: 14, height: 6).offset(x: 12, y: 2)
            Blossom(petal: Theme.pink, size: 7).offset(x: 13, y: 0)
        }
        .frame(width: 64, height: 26)
    }
}

private struct Tent: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Triangle().fill(LinearGradient(colors: [Color(hex: 0xFFB35C), Color(hex: 0xE87A2E)], startPoint: .top, endPoint: .bottom))
                .frame(width: 54, height: 40)
            Triangle().fill(Color(hex: 0x6B3A1E)).frame(width: 16, height: 20)
            Triangle().fill(Color(hex: 0xFFE3B8).opacity(0.5)).frame(width: 4, height: 40).offset(x: -1)
            Rectangle().fill(Color(hex: 0x8A5A36)).frame(width: 1.5, height: 14).offset(y: -38)
            Triangle().fill(Theme.pink).frame(width: 10, height: 7).rotationEffect(.degrees(90)).offset(x: 5, y: -46)
        }
        .frame(width: 58, height: 48)
    }
}

private struct Windmill: View {
    @State private var spin = false
    var body: some View {
        ZStack(alignment: .bottom) {
            Trapezoid().fill(LinearGradient(colors: [Color(hex: 0xF6E7CF), Color(hex: 0xD9BE98)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 30, height: 52)
            UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5).fill(Color(hex: 0x8A5A36))
                .frame(width: 9, height: 13)
            Triangle().fill(Color(hex: 0xD9483E)).frame(width: 30, height: 14).offset(y: -50)
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [.white, Color(hex: 0xDDE4FF)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 8, height: 26)
                        .offset(y: -15)
                        .rotationEffect(.degrees(Double(i) * 90))
                }
                Circle().fill(Color(hex: 0x8A5A36)).frame(width: 7)
            }
            .rotationEffect(.degrees(spin ? 360 : 0))
            .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: spin)
            .offset(y: -50)
        }
        .frame(width: 62, height: 86)
        .onAppear { spin = true }
    }
}

private struct Trapezoid: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.2, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.2, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct Lighthouse: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Trapezoid().fill(.white).frame(width: 26, height: 66)
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in Rectangle().fill(Color(hex: 0xE24A4A)).frame(height: 8) }
            }
            .frame(width: 26, height: 66)
            .mask(Trapezoid().frame(width: 26, height: 66))
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0x3A3F80)).frame(width: 26, height: 4).offset(y: -66)
            ZStack {
                Circle().fill(Theme.gold.opacity(0.4)).frame(width: 30).blur(radius: 5)
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xFFE38A)).frame(width: 14, height: 12)
            }
            .offset(y: -72)
            Triangle().fill(Color(hex: 0xE24A4A)).frame(width: 20, height: 10).offset(y: -84)
        }
        .frame(width: 36, height: 92)
    }
}

private struct Rocket: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // 尾焰
            Ellipse().fill(LinearGradient(colors: [Theme.gold, Color(hex: 0xFF7A3A).opacity(0)], startPoint: .top, endPoint: .bottom))
                .frame(width: 10, height: 14).offset(y: 6)
            // 尾翼
            Triangle().fill(Color(hex: 0xE24A4A)).frame(width: 12, height: 18).rotationEffect(.degrees(-25)).offset(x: -12, y: -4)
            Triangle().fill(Color(hex: 0xE24A4A)).frame(width: 12, height: 18).rotationEffect(.degrees(25)).offset(x: 12, y: -4)
            // 机身
            Capsule().fill(LinearGradient(colors: [.white, Color(hex: 0xC9CDF0)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 22, height: 64).offset(y: -6)
            Circle().fill(Theme.cyan).frame(width: 10).overlay(Circle().stroke(Color(hex: 0x3A3F80), lineWidth: 2)).offset(y: -46)
            UnevenRoundedRectangle(topLeadingRadius: 11, topTrailingRadius: 11).fill(Color(hex: 0xE24A4A))
                .frame(width: 22, height: 14).offset(y: -56)
        }
        .frame(width: 40, height: 84)
    }
}

private struct Duck: View {
    var body: some View {
        let yellow = LinearGradient(colors: [Color(hex: 0xFFE680), Color(hex: 0xF5C02E)], startPoint: .top, endPoint: .bottom)
        ZStack {
            Ellipse().fill(yellow).frame(width: 30, height: 18).offset(x: -2, y: 7)
            Circle().fill(yellow).frame(width: 17).offset(x: 6, y: -6)
            Circle().fill(Color(hex: 0x23264F)).frame(width: 3).offset(x: 9, y: -8)
            Ellipse().fill(Color(hex: 0xFF9A3A)).frame(width: 9, height: 5).offset(x: 16, y: -4)
            Ellipse().fill(Color(hex: 0xF2B21C)).frame(width: 12, height: 7).rotationEffect(.degrees(-15)).offset(x: -6, y: 5)
        }
        .frame(width: 36, height: 32)
    }
}

private struct Cat: View {
    var body: some View {
        let fur = LinearGradient(colors: [Color(hex: 0xFFB866), Color(hex: 0xE8892E)], startPoint: .top, endPoint: .bottom)
        let ink = Color(hex: 0x23264F)
        ZStack {
            // 尾巴
            Capsule().fill(Color(hex: 0xE8892E)).frame(width: 6, height: 22).rotationEffect(.degrees(40)).offset(x: 14, y: 6)
            Ellipse().fill(fur).frame(width: 26, height: 22).offset(y: 9)
            Circle().fill(fur).frame(width: 22).offset(y: -7)
            Triangle().fill(Color(hex: 0xE8892E)).frame(width: 8, height: 9).rotationEffect(.degrees(-15)).offset(x: -7, y: -18)
            Triangle().fill(Color(hex: 0xE8892E)).frame(width: 8, height: 9).rotationEffect(.degrees(15)).offset(x: 7, y: -18)
            SmileArc().stroke(ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round)).frame(width: 5, height: 2).offset(x: -4, y: -8)
            SmileArc().stroke(ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round)).frame(width: 5, height: 2).offset(x: 4, y: -8)
            Ellipse().fill(Theme.pink).frame(width: 3, height: 2).offset(y: -4)
            Ellipse().fill(Color(hex: 0xFFF1DC)).frame(width: 12, height: 9).offset(y: 12)
        }
        .frame(width: 40, height: 40)
    }
}

private struct Penguin: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x2E3352)).frame(width: 26, height: 36).offset(y: 2)
            Ellipse().fill(.white).frame(width: 17, height: 26).offset(y: 5)
            HStack(spacing: 6) {
                Circle().fill(Color(hex: 0x23264F)).frame(width: 3.5)
                Circle().fill(Color(hex: 0x23264F)).frame(width: 3.5)
            }
            .offset(y: -8)
            Triangle().fill(Color(hex: 0xFFA23A)).frame(width: 6, height: 5).rotationEffect(.degrees(180)).offset(y: -3)
            Ellipse().fill(Color(hex: 0xFFA23A)).frame(width: 8, height: 4).offset(x: -6, y: 19)
            Ellipse().fill(Color(hex: 0xFFA23A)).frame(width: 8, height: 4).offset(x: 6, y: 19)
            Ellipse().fill(Theme.pink.opacity(0.5)).frame(width: 5, height: 3).offset(x: -8, y: -4)
            Ellipse().fill(Theme.pink.opacity(0.5)).frame(width: 5, height: 3).offset(x: 8, y: -4)
        }
        .frame(width: 32, height: 42)
    }
}

private struct Cloud: View {
    var body: some View {
        Blobs(circles: [.init(0.25, 0.65, 0.16), .init(0.45, 0.45, 0.22), .init(0.68, 0.55, 0.18), .init(0.85, 0.72, 0.11)])
            .fill(LinearGradient(colors: [.white, Color(hex: 0xD9E0FF)], startPoint: .top, endPoint: .bottom))
            .frame(width: 72, height: 36)
            .shadow(color: .white.opacity(0.3), radius: 6)
    }
}

private struct Meteors: View {
    var body: some View {
        ZStack {
            ForEach(Array([(-20.0, -12.0, 1.0), (14.0, 4.0, 0.75), (-4.0, 18.0, 0.6)].enumerated()), id: \.offset) { _, m in
                HStack(spacing: 0) {
                    Capsule().fill(LinearGradient(colors: [.white.opacity(0), .white.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 44 * m.2, height: 3)
                    StarShape(points: 4, inner: 0.4).fill(Color(hex: 0xFFF1A8)).frame(width: 12 * m.2, height: 12 * m.2)
                        .shadow(color: Theme.gold, radius: 4)
                }
                .rotationEffect(.degrees(28))
                .offset(x: m.0, y: m.1)
            }
        }
        .frame(width: 90, height: 56)
    }
}

private struct Balloon: View {
    var body: some View {
        ZStack(alignment: .top) {
            ZStack {
                Ellipse().fill(Color(hex: 0xFF6B6B)).frame(width: 40, height: 44)
                Ellipse().fill(Color(hex: 0xFFE066)).frame(width: 24, height: 44)
                Ellipse().fill(Color(hex: 0x66D9E8)).frame(width: 9, height: 44)
            }
            .clipShape(Ellipse())
            Path { p in
                p.move(to: CGPoint(x: 11, y: 38)); p.addLine(to: CGPoint(x: 17, y: 54))
                p.move(to: CGPoint(x: 35, y: 38)); p.addLine(to: CGPoint(x: 29, y: 54))
            }
            .stroke(Color(hex: 0xC9CDF0), lineWidth: 1)
            .frame(width: 46, height: 66)
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xB07A4F)).frame(width: 14, height: 10).offset(y: 54)
        }
        .frame(width: 46, height: 66)
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
