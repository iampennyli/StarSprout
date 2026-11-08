import SwiftUI
import SwiftData

/// 3:4 分享卡。只显示昵称，不出现真名、照片、学校。
struct MedalCardView: View {
    let def: MedalDef
    let earnedAt: Date
    let childName: String
    let planetName: String
    let showName: Bool
    let message: String
    let statLines: [(String, String)]
    var width: CGFloat = 360

    var body: some View {
        let h = width * 4 / 3
        let color = def.rarity.color
        VStack(spacing: 8) {
            Text(def.rarity.title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12).padding(.vertical, 3)
                .background(color, in: Capsule())
            MedalEmblem(glyph: def.glyph, color: color, size: width * 0.39)
            Text(def.name).font(Theme.titleFont(30)).foregroundStyle(.white)
            Text(def.subtitle).font(.subheadline).foregroundStyle(Theme.muted)
            if !statLines.isEmpty {
                HStack(spacing: 28) {
                    ForEach(Array(statLines.enumerated()), id: \.offset) { _, s in
                        VStack(spacing: 2) {
                            Text(s.1).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.white)
                            Text(s.0).font(.caption2).foregroundStyle(Theme.muted)
                        }
                    }
                }
            }
            Text(def.blurb).font(.footnote).foregroundStyle(.white).multilineTextAlignment(.center)
            if !message.isEmpty {
                Text(message)
                    .font(.caption.weight(.semibold)).foregroundStyle(Theme.ink)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color(hex: 0xFFF1D6), in: RoundedRectangle(cornerRadius: 10))
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(showName ? "\(childName) · \(planetName)星球" : "\(planetName)星球的探险家")
                        .font(.footnote.bold()).foregroundStyle(.white)
                    Text("\(earnedAt.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))) 获得 · 运动星球")
                        .font(.caption2).foregroundStyle(Theme.muted)
                }
                Spacer()
                // TODO: 替换成落地页二维码
                RoundedRectangle(cornerRadius: 6).fill(.white)
                    .frame(width: 46, height: 46)
                    .overlay(Image(systemName: "qrcode").font(.system(size: 34)).foregroundStyle(Theme.ink))
            }
            .padding(.top, 10)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.stroke).frame(height: 1)
            }
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 16)
        .frame(width: width, height: h)
        .background(Theme.bg)
        .background(alignment: .top) { StarField().frame(height: h * 0.3) }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(color, lineWidth: 3))
    }
}

/// 卡片上印的真实数据
func medalStatLines(_ def: MedalDef, stats: MedalStats) -> [(String, String)] {
    [("跳绳", "\(Int(stats.ropeTotal).formatted()) 个"),
     ("跑步", "\(stats.runTotal.clean) km"),
     ("打卡", "\(stats.activeDays) 天")]
}

// MARK: - Unlock ceremony

struct MedalUnlockView: View {
    let record: MedalRecord
    var onDone: () -> Void

    @Query private var settingsList: [AppSettings]
    @Query private var checkIns: [CheckIn]
    @Query private var trees: [TreeState]
    @State private var flipped = false
    @State private var sharing = false

    var body: some View {
        let def = MedalCatalog.def(record.medalID)
        ZStack {
            Theme.bgDeep.ignoresSafeArea()
            StarField()
            if let def {
                VStack(spacing: 16) {
                    Text("获得新勋章！").font(Theme.titleFont(30))
                    MedalCardView(def: def, earnedAt: record.earnedAt,
                                  childName: settingsList.first?.childName ?? "",
                                  planetName: settingsList.first?.planetName ?? "",
                                  showName: true, message: "",
                                  statLines: medalStatLines(def, stats: GameEngine.stats(checkIns: checkIns, tree: trees.first ?? TreeState())),
                                  width: 300)
                        .rotation3DEffect(.degrees(flipped ? 0 : 90), axis: (x: 0, y: 1, z: 0))
                        .scaleEffect(flipped ? 1 : 0.6)
                    Text("这枚勋章永远属于你").font(.footnote).foregroundStyle(Theme.muted)
                    Spacer(minLength: 0)
                    HStack(spacing: 10) {
                        Button("收下", action: onDone).buttonStyle(OutlineButtonStyle(color: .white, height: 54))
                        Button("分享给家人") { sharing = true }.buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background {
                    // 光晕和光芒只做背景，不参与布局，避免把按钮撑出屏幕
                    ZStack {
                        Circle().fill(def.rarity.color.opacity(0.08)).frame(width: 520, height: 520)
                        RaysView(color: def.rarity.color).frame(width: 420, height: 420).opacity(flipped ? 1 : 0)
                    }
                    .offset(y: -60)
                    .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            SoundManager.shared.play(.medal)
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) { flipped = true }
        }
        .onTapGesture { if !flipped { flipped = true } }
        .sensoryFeedback(.success, trigger: flipped)
        .sheet(isPresented: $sharing, onDismiss: onDone) {
            if let def { MedalShareView(def: def, record: record) }
        }
    }
}

// MARK: - Share panel

struct MedalShareView: View {
    let def: MedalDef
    let record: MedalRecord?

    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [AppSettings]
    @Query private var checkIns: [CheckIn]
    @Query private var trees: [TreeState]

    @State private var showName = true
    @State private var message = "说到做到，为你骄傲！"
    @State private var unlocked = false
    @State private var askPIN = false
    @State private var image: Image?

    private var card: MedalCardView {
        MedalCardView(def: def, earnedAt: record?.earnedAt ?? .now,
                      childName: settingsList.first?.childName ?? "",
                      planetName: settingsList.first?.planetName ?? "",
                      showName: showName, message: message,
                      statLines: medalStatLines(def, stats: GameEngine.stats(checkIns: checkIns, tree: trees.first ?? TreeState())))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    card.scaleEffect(0.85).frame(width: 306, height: 408)
                    VStack(spacing: 0) {
                        Toggle("显示昵称「\(settingsList.first?.childName ?? "")」", isOn: $showName)
                            .frame(minHeight: 44)
                        Divider().overlay(Theme.stroke)
                        HStack {
                            Text("家长寄语")
                            TextField("可以不填", text: $message)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Theme.muted)
                        }
                        .frame(minHeight: 44)
                    }
                    .card(padding: 14, radius: 16)

                    if unlocked, let image {
                        ShareLink(item: image, preview: SharePreview(def.name, image: image)) {
                            Label("分享给家人", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("分享给家人") { askPIN = true }.buttonStyle(PrimaryButtonStyle())
                    }
                    Text("分享前需要输入家长密码 · 卡片不含真名、照片和学校")
                        .font(.caption).foregroundStyle(Theme.muted)
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("分享勋章")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
            }
            .sheet(isPresented: $askPIN) {
                PINGateView(title: "家长确认分享") {
                    askPIN = false
                    render()
                    unlocked = true
                }
            }
            .onChange(of: showName) { _, _ in if unlocked { render() } }
            .onChange(of: message) { _, _ in if unlocked { render() } }
        }
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: card.environment(\.colorScheme, .dark))
        renderer.scale = 3
        if let ui = renderer.uiImage { image = Image(uiImage: ui) }
    }
}
