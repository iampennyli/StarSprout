import SwiftUI
import SwiftData

struct VaultView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @Query private var checkIns: [CheckIn]
    @Query private var trees: [TreeState]
    @Query private var medals: [MedalRecord]
    @Query private var requests: [RedemptionRequest]
    @Query private var settingsList: [AppSettings]

    var openParent: () -> Void

    @State private var sharing: MedalDef?
    @State private var screenDialog = false
    @State private var toast: String?

    private var settings: AppSettings? { settingsList.first }
    private var money: Double { GameEngine.balance(.money, entries) }
    private var screen: Double { GameEngine.balance(.screen, entries, settings: settings) }
    private var coins: Double { GameEngine.balance(.coins, entries) }
    private func openRequest(_ c: Currency) -> Double {
        requests.filter { !$0.done && $0.currencyRaw == c.rawValue }.reduce(0) { $0 + $1.amount }
    }
    private var earnedIDs: Set<String> { Set(medals.map(\.medalID)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("宝库").font(Theme.titleFont(30)).padding(.top, 8)

                balanceCard(title: "零花钱", value: "¥" + String(format: "%.2f", money), color: Theme.mint,
                            note: pendingNote(.money), button: "申请提现") {
                    let available = money - openRequest(.money)
                    if available > 0, GameEngine.requestRedemption(.money, amount: available, ctx: ctx) {
                        show("已经告诉爸爸妈妈啦，等他们给你 \(available.clean) 元")
                    } else { show("现在没有可以提现的零花钱") }
                }
                balanceCard(title: (settings?.screenTimeWeeklyExpiry ?? true) ? "屏幕时间 · 本周日前有效" : "屏幕时间",
                            value: "\(Int(screen)) 分钟", color: Theme.cyan,
                            note: pendingNote(.screen), button: "申请使用") { screenDialog = true }
                coinsCard
                recentList
                medalWall
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .confirmationDialog("想用多少屏幕时间？", isPresented: $screenDialog, titleVisibility: .visible) {
            let available = screen - openRequest(.screen)
            ForEach([10.0, 15.0, 30.0].filter { $0 <= available }, id: \.self) { m in
                Button("\(Int(m)) 分钟") { requestScreen(m) }
            }
            if available > 0 { Button("全部（\(Int(available)) 分钟）") { requestScreen(available) } }
        }
        .sheet(item: $sharing) { def in
            MedalShareView(def: def, record: medals.first { $0.medalID == def.id })
        }
        .overlay(alignment: .top) {
            if let toast {
                Text(toast).font(.subheadline.bold()).foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Theme.lime, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func requestScreen(_ m: Double) {
        if GameEngine.requestRedemption(.screen, amount: m, ctx: ctx) {
            show("已经告诉爸爸妈妈，等他们放行 \(Int(m)) 分钟")
        }
    }

    private func show(_ text: String) {
        withAnimation { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { withAnimation { toast = nil } }
    }

    private func pendingNote(_ c: Currency) -> String? {
        let pending = GameEngine.pendingAmount(c, entries)
        let open = openRequest(c)
        var parts: [String] = []
        if pending > 0 { parts.append("待确认 " + (c == .money ? "\(pending.clean) 元" : "\(Int(pending)) 分钟")) }
        if open > 0 { parts.append("申请中 " + (c == .money ? "\(open.clean) 元" : "\(Int(open)) 分钟")) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func balanceCard(title: String, value: String, color: Color, note: String?, button: String,
                             action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(Theme.muted)
                Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(color)
                if let note { Text(note).font(.caption2).foregroundStyle(Theme.muted) }
            }
            Spacer()
            Button(button, action: action)
                .font(.subheadline.bold()).foregroundStyle(Theme.ink)
                .padding(.horizontal, 16).frame(height: 44)
                .background(color, in: RoundedRectangle(cornerRadius: 14))
        }
        .card(radius: 18)
    }

    private var coinsCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("金币 · 只在星球上使用").font(.caption).foregroundStyle(Theme.muted)
                Text("\(Int(coins))").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(Theme.gold)
            }
            Spacer()
            Text("施肥、买装饰都要用").font(.caption).foregroundStyle(Theme.muted)
        }
        .card(radius: 18)
    }

    private var recentList: some View {
        let recent = entries.filter { $0.currency != .water }.prefix(3)
        return VStack(alignment: .leading, spacing: 0) {
            if recent.isEmpty {
                Text("还没有记录，去完成第一个任务吧").font(.subheadline).foregroundStyle(Theme.muted).padding(.vertical, 10)
            }
            ForEach(Array(recent.enumerated()), id: \.element.id) { i, e in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.reason).font(.subheadline)
                        Text(e.date.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN"))) + (e.pending ? " · 待确认" : ""))
                            .font(.caption2).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Text(amountText(e)).font(.subheadline.bold()).foregroundStyle(color(e))
                }
                .padding(.vertical, 10)
                if i < recent.count - 1 { Divider().overlay(Theme.stroke) }
            }
        }
        .card(padding: 14, radius: 18)
    }

    private func amountText(_ e: LedgerEntry) -> String {
        let sign = e.amount > 0 ? "+" : "−"
        let v = abs(e.amount)
        switch e.currency {
        case .money: return "\(sign)\(v.clean) 元"
        case .screen: return "\(sign)\(Int(v)) 分钟"
        case .coins: return "\(sign)\(Int(v)) 金币"
        case .water: return "\(sign)\(Int(v)) 水"
        }
    }

    private func color(_ e: LedgerEntry) -> Color {
        guard e.amount > 0 else { return Theme.muted }
        switch e.currency {
        case .money: return Theme.mint
        case .screen: return Theme.cyan
        default: return Theme.gold
        }
    }

    /// 只展示已经获得的勋章，按目录顺序（坚持 / 跳绳 / 跑步 / 成长 / 突破）
    private var earnedDefs: [MedalDef] { MedalCatalog.all.filter { earnedIDs.contains($0.id) } }

    private var medalWall: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("勋章 · 已获得 \(earnedDefs.count) 枚").font(.subheadline).foregroundStyle(Theme.muted)
                Spacer()
                if !earnedDefs.isEmpty {
                    Text("点开可分享").font(.caption).foregroundStyle(Theme.muted)
                }
            }
            if earnedDefs.isEmpty {
                Text("完成第一次运动，就能拿到第一枚勋章")
                    .font(.footnote).foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .card()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 12) {
                    ForEach(earnedDefs) { def in
                        Button { sharing = def } label: {
                            VStack(spacing: 4) {
                                MedalEmblem(glyph: def.glyph, color: def.rarity.color, size: 58)
                                Text(def.name)
                                    .font(.caption2).foregroundStyle(.white)
                                    .lineLimit(1).minimumScaleFactor(0.7)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(def.name)，点击分享")
                    }
                }
            }
        }
        .padding(.top, 4)
    }
}
