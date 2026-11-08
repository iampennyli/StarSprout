import SwiftUI

/// 用基础图形画的小树（占位美术，正式版替换成 Lottie / Rive 动画）。
/// 固定画布 240×260，树根在底部中间。
struct TreeView: View {
    var stage: Int
    var mood: TreeMood = .normal

    private var leafA: Color {
        switch mood {
        case .normal: return Theme.leaf
        case .thirsty: return Color(hex: 0xA6CF7E)
        case .sleepy, .hibernating: return Color(hex: 0x3E7F5A)
        }
    }
    private var leafB: Color {
        switch mood {
        case .normal: return Theme.leafDark
        case .thirsty: return Color(hex: 0x8DBF66)
        case .sleepy, .hibernating: return Color(hex: 0x346E4E)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            switch stage {
            case ...1: seed
            case 2: sprout
            case 3: sapling
            default: grownTree
            }
        }
        .frame(width: 240, height: 260, alignment: .bottom)
        .overlay(alignment: .topTrailing) {
            if mood == .sleepy {
                Text("z z").font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.muted).padding(.top, stage >= 4 ? 20 : 140).padding(.trailing, 30)
            }
            if mood == .thirsty {
                Image(systemName: "drop.fill").font(.system(size: 22)).foregroundStyle(Theme.cyan)
                    .padding(10).background(.white, in: Circle())
                    .padding(.top, stage >= 4 ? 10 : 130).padding(.trailing, 20)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("小树，第 \(stage) 阶段" + (mood.message.map { "，\($0)" } ?? ""))
    }

    private var seed: some View {
        Ellipse().fill(Theme.trunk).frame(width: 30, height: 20)
            .overlay(Capsule().fill(Color(hex: 0x8A5A36)).frame(width: 12, height: 3).offset(y: -3))
            .padding(.bottom, 2)
    }

    private var sprout: some View {
        ZStack(alignment: .bottom) {
            Capsule().fill(Theme.leafDark).frame(width: 6, height: 44)
            Ellipse().fill(leafA).frame(width: 32, height: 16).rotationEffect(.degrees(-25)).offset(x: -16, y: -36)
            Ellipse().fill(leafA).frame(width: 32, height: 16).rotationEffect(.degrees(25)).offset(x: 16, y: -40)
        }
    }

    private var sapling: some View {
        ZStack(alignment: .bottom) {
            Capsule().fill(Color(hex: 0x8A6A3A)).frame(width: 7, height: 90)
            Ellipse().fill(leafA).frame(width: 40, height: 20).rotationEffect(.degrees(-25)).offset(x: -20, y: -46)
            Ellipse().fill(leafA).frame(width: 40, height: 20).rotationEffect(.degrees(25)).offset(x: 20, y: -58)
            Ellipse().fill(leafB).frame(width: 34, height: 18).rotationEffect(.degrees(-30)).offset(x: -16, y: -76)
            Ellipse().fill(leafB).frame(width: 34, height: 18).rotationEffect(.degrees(30)).offset(x: 16, y: -84)
        }
    }

    private var grownTree: some View {
        let scale: CGFloat = stage == 4 ? 0.8 : 1.0
        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 9).fill(Theme.trunk).frame(width: 24, height: 112)
            ZStack {
                Circle().fill(leafA).frame(width: 150, height: 150)
                Circle().fill(leafB).frame(width: 90, height: 90).offset(x: -52, y: 30)
                Circle().fill(leafB).frame(width: 90, height: 90).offset(x: 52, y: 28)
                Circle().fill(Theme.leafLight).frame(width: 22, height: 22).offset(x: -22, y: -34)
                    .opacity(mood == .normal ? 1 : 0)
                if stage >= 6 && mood == .normal { flowers }
                if stage >= 7 && mood == .normal { fruits }
                if mood == .hibernating {
                    Capsule().fill(.white).frame(width: 130, height: 36).offset(y: -62)
                }
            }
            .padding(.bottom, 92)
        }
        .scaleEffect(x: 1, y: mood == .thirsty ? 0.95 : 1, anchor: .bottom)
        .scaleEffect(scale, anchor: .bottom)
    }

    private var flowers: some View {
        ZStack {
            ForEach(Array([(-30.0, -40.0), (24.0, -50.0), (12.0, 10.0), (-60.0, 24.0), (58.0, 20.0)].enumerated()), id: \.offset) { _, p in
                Circle().fill(Theme.pink).frame(width: 13, height: 13).offset(x: p.0, y: p.1)
            }
        }
    }

    private var fruits: some View {
        ZStack {
            ForEach(Array([(-14.0, -46.0), (36.0, -6.0), (-48.0, 12.0)].enumerated()), id: \.offset) { _, p in
                Image(systemName: "star.fill").font(.system(size: 18)).foregroundStyle(Theme.gold).offset(x: p.0, y: p.1)
            }
        }
    }
}

/// 大树阶段来做客的小兔子
struct BunnyView: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xE9ECFF)).frame(width: 9, height: 22).offset(x: -5, y: -16)
            Ellipse().fill(Color(hex: 0xE9ECFF)).frame(width: 9, height: 22).offset(x: 5, y: -16)
            Ellipse().fill(Color(hex: 0xE9ECFF)).frame(width: 30, height: 22)
            Circle().fill(Theme.ink).frame(width: 4, height: 4).offset(x: -6, y: -2)
        }
        .frame(width: 34, height: 44)
    }
}
