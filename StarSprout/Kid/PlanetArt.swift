import SwiftUI

/// 星球本体：带光照的球体、陨石坑、边缘光和大气光晕。
/// 第 6 阶段解锁「整颗星球变色」，从紫蓝色变成青绿色。
struct PlanetBody: View {
    var stage: Int
    var diameter: CGFloat = 340

    private var colors: (light: Color, base: Color, dark: Color, glow: Color) {
        stage >= 6
            ? (Color(hex: 0x86F0D2), Color(hex: 0x33AE96), Color(hex: 0x1B6A6A), Color(hex: 0x5BE0C2))
            : (Color(hex: 0x8C95F5), Color(hex: 0x4C55B8), Color(hex: 0x2C327E), Color(hex: 0x7A84F0))
    }

    var body: some View {
        let c = colors, d = diameter
        ZStack {
            // 大气光晕
            Circle().fill(c.glow.opacity(0.35)).frame(width: d * 1.08, height: d * 1.08).blur(radius: d * 0.05)
            // 球体
            Circle().fill(RadialGradient(colors: [c.light, c.base, c.dark], center: UnitPoint(x: 0.32, y: 0.12),
                                         startRadius: d * 0.02, endRadius: d * 0.75))
            // 陨石坑（只画在露出来的上半部分）
            crater(size: d * 0.12, x: -0.30, y: -0.36, c)
            crater(size: d * 0.07, x: 0.30, y: -0.34, c)
            crater(size: d * 0.05, x: -0.08, y: -0.27, c)
            crater(size: d * 0.09, x: 0.38, y: -0.18, c)
            // 边缘光
            Circle().stroke(LinearGradient(colors: [.white.opacity(0.55), .clear], startPoint: .top, endPoint: .center),
                            lineWidth: 3)
        }
        .frame(width: d, height: d)
    }

    private func crater(size: CGFloat, x: CGFloat, y: CGFloat, _ c: (light: Color, base: Color, dark: Color, glow: Color)) -> some View {
        Ellipse().fill(c.dark.opacity(0.55))
            .overlay(alignment: .bottom) {
                Ellipse().fill(c.light.opacity(0.35)).frame(height: size * 0.18).padding(.horizontal, size * 0.15)
            }
            .frame(width: size, height: size * 0.62)
            .offset(x: x * diameter, y: y * diameter)
    }
}

/// 星球顶上的草地。种子阶段是一小块土；小树苗以后长出草和小草叶；小树阶段开出第一朵花。
struct GrassCap: View {
    var stage: Int

    var body: some View {
        let grassy = stage >= 3
        let w: CGFloat = grassy ? 210 : 112
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(grassy
                      ? LinearGradient(colors: [Color(hex: 0x8BEA9F), Color(hex: 0x3FB06E)], startPoint: .top, endPoint: .bottom)
                      : LinearGradient(colors: [Color(hex: 0xB98157), Color(hex: 0x7E4F2E)], startPoint: .top, endPoint: .bottom))
                .frame(width: w, height: grassy ? 34 : 22)
            if grassy {
                // 草叶
                ForEach(Array(Self.blades.enumerated()), id: \.offset) { _, b in
                    Capsule().fill(Color(hex: 0x5ED488))
                        .frame(width: 4, height: b.h)
                        .rotationEffect(.degrees(b.angle), anchor: .bottom)
                        .offset(x: b.x, y: -18)
                }
            }
            if stage >= 4 {
                Blossom(petal: Theme.pink, size: 16).offset(x: -70, y: -24)
                Capsule().fill(Color(hex: 0x3FB06E)).frame(width: 2.5, height: 10).offset(x: -70, y: -14)
            }
            if stage >= 6 {
                Blossom(petal: Theme.gold, size: 13).offset(x: 78, y: -20)
                Capsule().fill(Color(hex: 0x3FB06E)).frame(width: 2.5, height: 8).offset(x: 78, y: -12)
            }
        }
        .frame(width: 230, height: 60, alignment: .bottom)
    }

    private static let blades: [(x: CGFloat, h: CGFloat, angle: Double)] = [
        (-88, 12, -18), (-80, 9, 12), (-46, 11, -8), (-38, 8, 16), (40, 10, -14), (50, 13, 10), (86, 9, 18), (93, 11, -10)
    ]
}
