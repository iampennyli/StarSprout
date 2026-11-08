import SwiftUI

/// 顶部余额小卡
struct BalanceChip: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(Theme.muted)
            Text(value).font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .card(padding: 10, radius: 14)
    }
}

/// 小标签，例如 "+10 金币"
struct RewardPill: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 10).padding(.vertical, 3)
            .background(color, in: Capsule())
    }
}

/// 勋章图案：外圈光芒 + 稀有度颜色圆环 + 中间文字
struct MedalEmblem: View {
    let glyph: String
    let color: Color
    var size: CGFloat = 54

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: size * 0.027, height: size * 0.09)
                    .offset(y: -size * 0.44)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            Circle().fill(color).frame(width: size * 0.72, height: size * 0.72)
            Circle().fill(Theme.card).frame(width: size * 0.61, height: size * 0.61)
            Circle()
                .strokeBorder(color, style: StrokeStyle(lineWidth: max(1, size * 0.013), dash: [3, 4]))
                .frame(width: size * 0.61, height: size * 0.61)
            Text(glyph)
                .font(.system(size: size * (glyph.count <= 1 ? 0.3 : glyph.count == 2 ? 0.23 : 0.19), weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.5)
                .frame(width: size * 0.5)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// 星空背景点
struct StarField: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let points: [(CGFloat, CGFloat, CGFloat)] = [
                (0.08, 0.06, 1.5), (0.36, 0.03, 1), (0.6, 0.09, 1.5), (0.78, 0.02, 1),
                (0.9, 0.14, 1.5), (0.2, 0.18, 1), (0.66, 0.22, 1), (0.05, 0.3, 1)
            ]
            ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                Circle().fill(.white.opacity(0.8))
                    .frame(width: p.2 * 2, height: p.2 * 2)
                    .position(x: p.0 * w, y: p.1 * h)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// 进度条
struct ProgressBar: View {
    var value: Double   // 0...1
    var color: Color = Theme.leaf
    var height: CGFloat = 10
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.bg)
                Capsule().fill(color).frame(width: max(height, geo.size.width * min(1, max(0, value))))
                    .animation(.easeOut(duration: 0.6), value: value)
            }
        }
        .frame(height: height)
    }
}

/// 家长模式标识
struct ParentModeBadge: View {
    var body: some View {
        Text("家长模式")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Theme.gold)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 10).frame(height: 26)
            .overlay(Capsule().stroke(Theme.gold, lineWidth: 1))
    }
}
