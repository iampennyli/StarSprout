import Foundation

/// 装饰放在哪里。每个位置同一时间只能换上一件。
enum DecorSlot: String, CaseIterable, Identifiable {
    case hat, ornament, ground, landmark, pet, sky, ring
    var id: String { rawValue }
    var title: String {
        switch self {
        case .hat: return "树顶"
        case .ornament: return "挂饰"
        case .ground: return "草地"
        case .landmark: return "地标"
        case .pet: return "伙伴"
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
/// 价格参考：一个任务每天达标 +10 金币，所以 30 金币 ≈ 3 天，240 金币 ≈ 一个多月。
/// 新增装饰：在这里加一条，再在 Kid/DecorationArt.swift 里画出来（id 对应）。
enum DecorCatalog {
    static let all: [DecorItem] = [
        // 树顶
        DecorItem(id: "hat.star", name: "闪亮星星", slot: .hat, price: 40, minStage: 1, blurb: "像圣诞树顶那颗星"),
        DecorItem(id: "hat.bow", name: "粉色蝴蝶结", slot: .hat, price: 50, minStage: 1, blurb: "系在树顶，可爱加倍"),
        DecorItem(id: "hat.santa", name: "圣诞帽", slot: .hat, price: 60, minStage: 1, blurb: "叮叮当，叮叮当"),
        DecorItem(id: "hat.crown", name: "金色皇冠", slot: .hat, price: 80, minStage: 1, blurb: "小树也想当国王"),
        DecorItem(id: "hat.bird", name: "小蓝鸟", slot: .hat, price: 100, minStage: 3, blurb: "落在树顶唱歌"),

        // 挂饰
        DecorItem(id: "ornament.lantern", name: "红灯笼", slot: .ornament, price: 60, minStage: 3, blurb: "挂在树枝上"),
        DecorItem(id: "ornament.chime", name: "小风铃", slot: .ornament, price: 70, minStage: 3, blurb: "风一吹叮铃铃"),
        DecorItem(id: "ornament.stars", name: "星星挂坠", slot: .ornament, price: 80, minStage: 3, blurb: "把星星摘下来挂上"),
        DecorItem(id: "ornament.lights", name: "彩色灯串", slot: .ornament, price: 90, minStage: 3, blurb: "一闪一闪亮晶晶"),

        // 草地小物
        DecorItem(id: "ground.mushroom", name: "红蘑菇", slot: .ground, price: 30, minStage: 1, blurb: "草地上冒出来的"),
        DecorItem(id: "ground.flowers", name: "小花丛", slot: .ground, price: 35, minStage: 1, blurb: "五颜六色"),
        DecorItem(id: "ground.pumpkin", name: "大南瓜", slot: .ground, price: 40, minStage: 1, blurb: "圆滚滚"),
        DecorItem(id: "ground.pond", name: "小水池", slot: .ground, price: 90, minStage: 3, blurb: "还漂着一片荷叶"),
        DecorItem(id: "ground.swing", name: "小秋千", slot: .ground, price: 120, minStage: 4, blurb: "荡啊荡"),

        // 地标
        DecorItem(id: "landmark.tent", name: "小帐篷", slot: .landmark, price: 110, minStage: 3, blurb: "今晚在星球露营"),
        DecorItem(id: "ground.house", name: "小木屋", slot: .landmark, price: 150, minStage: 4, blurb: "窗户里亮着灯"),
        DecorItem(id: "landmark.windmill", name: "大风车", slot: .landmark, price: 160, minStage: 4, blurb: "呼呼地转"),
        DecorItem(id: "landmark.lighthouse", name: "灯塔", slot: .landmark, price: 200, minStage: 5, blurb: "给路过的飞船指路"),
        DecorItem(id: "landmark.rocket", name: "小火箭", slot: .landmark, price: 240, minStage: 5, blurb: "随时准备去探险"),

        // 伙伴
        DecorItem(id: "pet.duck", name: "小黄鸭", slot: .pet, price: 90, minStage: 1, blurb: "嘎嘎嘎"),
        DecorItem(id: "pet.cat", name: "小橘猫", slot: .pet, price: 120, minStage: 1, blurb: "喜欢在树下打盹"),
        DecorItem(id: "pet.penguin", name: "小企鹅", slot: .pet, price: 150, minStage: 3, blurb: "从南极来做客"),

        // 天空
        DecorItem(id: "sky.cloud", name: "白云朵", slot: .sky, price: 40, minStage: 1, blurb: "软绵绵"),
        DecorItem(id: "sky.moon", name: "弯弯月亮", slot: .sky, price: 50, minStage: 1, blurb: "挂在星球上空"),
        DecorItem(id: "sky.satellite", name: "小卫星", slot: .sky, price: 100, minStage: 1, blurb: "绕着星球巡逻"),
        DecorItem(id: "sky.meteor", name: "流星雨", slot: .sky, price: 120, minStage: 1, blurb: "快许个愿"),
        DecorItem(id: "sky.balloon", name: "热气球", slot: .sky, price: 130, minStage: 3, blurb: "慢慢飘过"),
        DecorItem(id: "sky.rainbow", name: "彩虹", slot: .sky, price: 140, minStage: 3, blurb: "雨过天晴"),

        // 星环
        DecorItem(id: "ring.gold", name: "金色星环", slot: .ring, price: 80, minStage: 1, blurb: "闪闪发光"),
        DecorItem(id: "ring.ice", name: "冰晶星环", slot: .ring, price: 110, minStage: 1, blurb: "冰冰凉凉"),
        DecorItem(id: "ring.rainbow", name: "彩虹星环", slot: .ring, price: 150, minStage: 1, blurb: "七种颜色"),
    ]

    static func item(_ id: String) -> DecorItem? { all.first { $0.id == id } }
    static func items(in slot: DecorSlot) -> [DecorItem] { all.filter { $0.slot == slot } }
}
