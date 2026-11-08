import SwiftUI

/// 星际探险风格的设计 token，和画布上的设计稿一致
enum Theme {
    static let bg = Color(hex: 0x171A3D)
    static let bgDeep = Color(hex: 0x0F1130)
    static let card = Color(hex: 0x23275A)
    static let cardRaised = Color(hex: 0x2E3374)
    static let stroke = Color(hex: 0x3A3F80)
    static let nav = Color(hex: 0x12142F)
    static let muted = Color(hex: 0xB9BEE8)
    static let dim = Color(hex: 0x8A90C8)
    static let locked = Color(hex: 0x4A4F92)
    static let ink = Color(hex: 0x171A3D)

    static let lime = Color(hex: 0xB8F25B)   // 主操作
    static let cyan = Color(hex: 0x5BE0F2)   // 屏幕时间 / 水
    static let gold = Color(hex: 0xFFC94D)   // 金币
    static let mint = Color(hex: 0x8BE3A0)   // 零花钱
    static let pink = Color(hex: 0xFF7AC6)
    static let silver = Color(hex: 0xC9CDF0)

    static let leaf = Color(hex: 0x6EDB8F)
    static let leafDark = Color(hex: 0x4FC777)
    static let leafLight = Color(hex: 0xA8F0BC)
    static let planet = Color(hex: 0x4C55B8)
    static let planetShade = Color(hex: 0x3E469C)
    static let trunk = Color(hex: 0xB07A4F)

    static func titleFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

// MARK: - Modifiers & button styles

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = 20
    var fill: Color = Theme.card
    var border: Color = Theme.stroke
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(border, lineWidth: 1))
    }
}

extension View {
    func card(padding: CGFloat = 16, radius: CGFloat = 20, fill: Color = Theme.card, border: Color = Theme.stroke) -> some View {
        modifier(CardModifier(padding: padding, radius: radius, fill: fill, border: border))
    }
    func screenBackground() -> some View {
        background(Theme.bg.ignoresSafeArea())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.lime
    var height: CGFloat = 54
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    var color: Color = Theme.lime
    var height: CGFloat = 50
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(color, lineWidth: 2))
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
