import Foundation
import TrainerCore

enum SimpleTrainerAction: Equatable, Sendable {
    case write(featureID: String)
    case freeze(featureID: String)
    case increment(featureID: String)
    case incrementInventory(scope: IngredientsInventoryScope)
    case incrementJungleInventory(scope: JungleDLCInventoryScope)
    case patch(patchID: String)
    case patchGroup(patchIDs: [String])
    case valuePatch(patchID: String)
    case unavailable(reason: String)
}

struct SimpleTrainerOption: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let defaultValue: String
    let showsValue: Bool
    let action: SimpleTrainerAction

    var isAvailable: Bool {
        if case .unavailable = action {
            return false
        }
        return true
    }

    var unavailableReason: String? {
        if case .unavailable(let reason) = action {
            return reason
        }
        return nil
    }

    var enabledStateID: String? {
        switch action {
        case .patch(let patchID), .valuePatch(let patchID):
            return patchID
        case .write, .freeze, .increment, .incrementInventory, .incrementJungleInventory, .patchGroup, .unavailable:
            return nil
        }
    }

    var enabledStateIDs: Set<String> {
        switch action {
        case .patch(let patchID), .valuePatch(let patchID):
            return [patchID]
        case .patchGroup(let patchIDs):
            return Set(patchIDs)
        case .write, .freeze, .increment, .incrementInventory, .incrementJungleInventory, .unavailable:
            return []
        }
    }

    var manifestFeatureID: String {
        switch action {
        case .write(let featureID), .freeze(let featureID), .increment(let featureID):
            return featureID
        case .incrementInventory(let scope):
            return scope.manifestFeatureID
        case .incrementJungleInventory(let scope):
            return scope.manifestFeatureID
        case .patch(let patchID), .valuePatch(let patchID):
            return patchID
        case .patchGroup:
            return id
        case .unavailable:
            return id
        }
    }

    var isMomentary: Bool {
        switch action {
        case .increment, .incrementInventory, .incrementJungleInventory:
            return true
        case .write, .freeze, .patch, .patchGroup, .valuePatch, .unavailable:
            return false
        }
    }

    var usesToggle: Bool {
        switch action {
        case .freeze, .patch, .patchGroup:
            return true
        case .write, .increment, .incrementInventory, .incrementJungleInventory, .valuePatch, .unavailable:
            return false
        }
    }
}

struct SimpleTrainerActionRequest: Sendable {
    let option: SimpleTrainerOption
    let isEnabled: Bool
    let valueText: String
}

enum SimpleTrainerOptions {
    private static let enabledPatchDefaultValue = "1"
    private static let playerSpeedDefaultValue = "5"
    private static let superDamageDefaultValue = "2.0"
    private static let currencyDefaultValue = "99999"
    private static let inventoryDefaultValue = "999"
    static let divingGodPatchIDs = ["god", "oxygen", "ammo", "crabTraps", "weight", "damage", "drones"]

    static let diving: [SimpleTrainerOption] = [
        SimpleTrainerOption(id: "divingGod", title: "God 模式（Diving 全开）", defaultValue: enabledPatchDefaultValue, showsValue: false, action: .patchGroup(patchIDs: divingGodPatchIDs)),
        SimpleTrainerOption(id: "god", title: "无敌/忽略伤害", defaultValue: enabledPatchDefaultValue, showsValue: false, action: .patch(patchID: "god")),
        SimpleTrainerOption(id: "oxygen", title: "无限氧气", defaultValue: enabledPatchDefaultValue, showsValue: false, action: .patch(patchID: "oxygen")),
        SimpleTrainerOption(id: "ammo", title: "无限弹药/鱼叉资源", defaultValue: enabledPatchDefaultValue, showsValue: false, action: .patch(patchID: "ammo")),
        SimpleTrainerOption(id: "crabTraps", title: "无限鱼笼", defaultValue: enabledPatchDefaultValue, showsValue: false, action: .patch(patchID: "crabTraps")),
        SimpleTrainerOption(id: "weight", title: "无限负重", defaultValue: enabledPatchDefaultValue, showsValue: false, action: .patch(patchID: "weight")),
        SimpleTrainerOption(id: "swimSpeed", title: "设置玩家移动速度", defaultValue: playerSpeedDefaultValue, showsValue: true, action: .valuePatch(patchID: "swimSpeed")),
        SimpleTrainerOption(id: "damage", title: "超级伤害/一击必杀", defaultValue: superDamageDefaultValue, showsValue: false, action: .patch(patchID: "damage")),
        SimpleTrainerOption(id: "drones", title: "无限无人机", defaultValue: enabledPatchDefaultValue, showsValue: false, action: .patch(patchID: "drones"))
    ]

    static let currencies: [SimpleTrainerOption] = [
        SimpleTrainerOption(id: "money", title: "增加金币", defaultValue: currencyDefaultValue, showsValue: true, action: .increment(featureID: "gold")),
        SimpleTrainerOption(id: "bei", title: "增加鲛人族贝壳", defaultValue: currencyDefaultValue, showsValue: true, action: .increment(featureID: "bei")),
        SimpleTrainerOption(id: "jungleGold", title: "增加丛林货币", defaultValue: currencyDefaultValue, showsValue: true, action: .increment(featureID: "jungleGold"))
    ]

    static let inventory: [SimpleTrainerOption] = [
        SimpleTrainerOption(id: "ingredients", title: "增加主线全部食材/素材", defaultValue: inventoryDefaultValue, showsValue: true, action: .incrementInventory(scope: .all)),
        SimpleTrainerOption(id: "jungleIngredients", title: "增加丛林DLC食材/素材（已有）", defaultValue: inventoryDefaultValue, showsValue: true, action: .incrementJungleInventory(scope: .ingredientsAndVillageItems)),
        SimpleTrainerOption(id: "seaPeopleVillageItems", title: "增加鲛人村/丛林村庄物品（已有）", defaultValue: inventoryDefaultValue, showsValue: true, action: .incrementJungleInventory(scope: .villageItems)),
        SimpleTrainerOption(id: "fishIngredients", title: "按鱼肉食材分类增加", defaultValue: inventoryDefaultValue, showsValue: true, action: .incrementInventory(scope: .fish)),
        SimpleTrainerOption(id: "vegetableIngredients", title: "按蔬菜食材分类增加", defaultValue: inventoryDefaultValue, showsValue: true, action: .incrementInventory(scope: .vegetable)),
        SimpleTrainerOption(id: "seasoningIngredients", title: "按调味品分类增加", defaultValue: inventoryDefaultValue, showsValue: true, action: .incrementInventory(scope: .seasoning)),
        SimpleTrainerOption(id: "upgradeMaterials", title: "按强化素材分类增加", defaultValue: inventoryDefaultValue, showsValue: true, action: .incrementInventory(scope: .upgrade))
    ]

    static let sushiBar: [SimpleTrainerOption] = [
        SimpleTrainerOption(id: "stamina", title: "无限体力", defaultValue: enabledPatchDefaultValue, showsValue: false, action: .patch(patchID: "stamina")),
        SimpleTrainerOption(id: "wasabi", title: "无限芥末", defaultValue: inventoryDefaultValue, showsValue: false, action: .patch(patchID: "wasabi")),
        SimpleTrainerOption(id: "artisan", title: "增加主线/丛林匠人火焰", defaultValue: inventoryDefaultValue, showsValue: true, action: .increment(featureID: "artisan"))
    ]

    static let allPlayerOptions = diving + currencies + inventory + sushiBar
}

private extension IngredientsInventoryScope {
    var manifestFeatureID: String {
        switch self {
        case .all:
            return "ingredients"
        case .fish:
            return "fishIngredients"
        case .vegetable:
            return "vegetableIngredients"
        case .seasoning:
            return "seasoningIngredients"
        case .upgrade:
            return "upgradeMaterials"
        }
    }
}

private extension JungleDLCInventoryScope {
    var manifestFeatureID: String {
        switch self {
        case .ingredientsAndVillageItems, .ingredients:
            return "jungleIngredients"
        case .villageItems:
            return "seaPeopleVillageItems"
        }
    }
}
