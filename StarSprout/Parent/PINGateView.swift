import SwiftUI
import SwiftData

/// 家长密码门：进入家长模式、分享勋章前都要过这一关
struct PINGateView: View {
    let title: String
    var onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [AppSettings]
    @State private var pin = ""
    @State private var wrongTick = 0
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button("取消") { dismiss() }.foregroundStyle(Theme.muted)
            }
            Image(systemName: "lock.shield.fill").font(.system(size: 44)).foregroundStyle(Theme.gold)
            Text(title).font(Theme.titleFont(24))
            Text("请输入 4 位家长密码").foregroundStyle(Theme.muted)
            HStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < pin.count ? Theme.lime : Theme.card)
                        .overlay(Circle().stroke(Theme.stroke))
                        .frame(width: 20, height: 20)
                }
            }
            .phaseAnimator([0.0, -10, 10, -6, 0], trigger: wrongTick) { v, x in v.offset(x: x) } animation: { _ in .linear(duration: 0.06) }
            .onTapGesture { focused = true }

            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: pin) { _, new in
                    let digits = String(new.filter(\.isNumber).prefix(4))
                    if digits != new { pin = digits; return }
                    if digits.count == 4 { check(digits) }
                }
            Spacer()
        }
        .padding(24)
        .screenBackground()
        .presentationDetents([.medium])
        .onAppear { focused = true }
    }

    private func check(_ digits: String) {
        if digits == settingsList.first?.parentPIN {
            onSuccess()
        } else {
            wrongTick += 1
            pin = ""
        }
    }
}
