import Foundation

/// 装饰放在哪里。每个位置同一时间只能换上一件。
enum DecorSlot: String, CaseIterable, Identifiable {
    case hat, ornament, ground, sky, ring
    var id: String { rawValue }
    var title: String {
        switch self {
        case .hat: return "树顶"
        case .ornament: return "挂饰"
        case .ground: return "草地"
        case .sky: return "天空"
        case .ring: return "星环"
        }
    }
}

struct DecorItem: Identifiable, Equatable {
    let id: String
    let name: String
    let slot: DecorSlot
    let price: Int
    /// 小树长到第几阶段才能买（比如树屋要有大树才放得下）
    let minStage: Int
    let blurb: String
}

/// 装饰目录。装饰只改变外观，不影响成长；买了永远是你的，可以随时换上取下。
/// 价格参考：一个任务每天达标 +10 金币，所以 30 金币 ≈ 3 天，150 金币 ≈ 两三周。
enum DecorCatalog {
    static let all: [DecorItem] = [
        DecorItem(id: "hat.star", name: "闪亮星星", slot: .hat, price: 40, minStage: 1, blurb: "像圣诞树顶那颗星"),
        DecorItem(id: "hat.crown", name: "金色皇冠", slot: .hat, price: 80, minStage: 1, blurb: "小树也想当国王"),
        DecorItem(id: "hat.bird", name: "小蓝鸟", slot: .hat, price: 100, minStage: 3, blurb: "落在树顶唱歌"),

        DecorItem(id: "ornament.lantern", name: "红灯笼", slot: .ornament, price: 60, minStage: 3, blurb: "挂在树枝上"),
        DecorItem(id: "ornament.lights", name: "彩色灯串", slot: .ornament, price: 90, minStage: 3, blurb: "一闪一闪亮晶晶"),

        DecorItem(id: "ground.mushroom", name: "红蘑菇", slot: .ground, price: 30, minStage: 1, blurb: "草地上冒出来的"),
        DecorItem(id: "ground.swing", name: "小秋千", slot: .ground, price: 120, minStage: 4, blurb: "荡啊荡"),
        DecorItem(id: "ground.house", name: "小木屋", slot: .ground, price: 150, minStage: 4, blurb: "窗户里亮着灯"),

        DecorItem(id: "sky.moon", name: "弯弯月亮", slot: .sky, price: 50, minStage: 1, blurb: "挂在星球上空"),
        DecorItem(id: "sky.satellite", name: "小卫星", slot: .sky, price: 100, minStage: 1, blurb: "绕着星球巡逻"),
        DecorItem(id: "sky.rainbow", name: "彩虹", slot: .sky, price: 140, minStage: 3, blurb: "雨过天晴"),

        DecorItem(id: "ring.gold", name: "金色星环", slot: .ring, price: 80, minStage: 1, blurb: "闪闪发光"),
        DecorItem(id: "ring.rainbow", name: "彩虹星环", slot: .ring, price: 150, minStage: 1, blurb: "七种颜色"),
    ]

    static func item(_ id: String) -> DecorItem? { all.first { $0.id == id } }
    static func items(in slot: DecorSlot) -> [DecorItem] { all.filter { $0.slot == slot } }
}
