import XCTest
import TrainerCore
@testable import DaveTheTrainer

final class SimpleTrainerOptionTests: XCTestCase {
    private let playerSpeedOptionID = "swimSpeed"
    private let playerSpeedDefaultValue = "5"
    private let currencyDefaultValue = "99999"
    private let inventoryDefaultValue = "999"
    private let inventoryCategoryOptionIDs: Set<String> = [
        "fishIngredients",
        "vegetableIngredients",
        "seasoningIngredients",
        "upgradeMaterials"
    ]

    func testOneClickDefaultValuesMatchRequestedSimpleTrainerDefaults() throws {
        let speedOption = try option(withID: playerSpeedOptionID, in: SimpleTrainerOptions.diving)

        XCTAssertEqual(speedOption.defaultValue, playerSpeedDefaultValue)
        XCTAssertTrue(SimpleTrainerOptions.currencies.allSatisfy { $0.defaultValue == currencyDefaultValue })
    }

    func testDivingGodModeGroupsToggleableDivingPatches() throws {
        let option = try option(withID: "divingGod", in: SimpleTrainerOptions.diving)

        XCTAssertEqual(option.action, .patchGroup(patchIDs: SimpleTrainerOptions.divingGodPatchIDs))
        XCTAssertEqual(option.enabledStateIDs, Set(SimpleTrainerOptions.divingGodPatchIDs))
        XCTAssertTrue(option.usesToggle)
        XCTAssertFalse(option.showsValue)
        XCTAssertFalse(SimpleTrainerOptions.divingGodPatchIDs.contains(playerSpeedOptionID))
    }

    func testValueDrivenOptionsUseApplyButtonWithoutToggle() throws {
        let speedOption = try option(withID: playerSpeedOptionID, in: SimpleTrainerOptions.diving)
        let artisanOption = try option(withID: "artisan", in: SimpleTrainerOptions.sushiBar)

        XCTAssertFalse(speedOption.usesToggle)
        XCTAssertTrue(speedOption.showsValue)
        XCTAssertFalse(artisanOption.usesToggle)
        XCTAssertTrue(artisanOption.showsValue)
        XCTAssertTrue(SimpleTrainerOptions.currencies.allSatisfy { !$0.usesToggle && $0.showsValue })
        XCTAssertTrue(SimpleTrainerOptions.inventory.allSatisfy { !$0.usesToggle && $0.showsValue })
    }

    func testInventoryCategoriesExposeValuePatchInputs() {
        let categoryOptions = SimpleTrainerOptions.inventory.filter { inventoryCategoryOptionIDs.contains($0.id) }
        let incrementScopes = Set(categoryOptions.compactMap(inventoryIncrementScopeID))

        XCTAssertEqual(categoryOptions.count, inventoryCategoryOptionIDs.count)
        XCTAssertEqual(incrementScopes, inventoryCategoryOptionIDs)
        XCTAssertTrue(categoryOptions.allSatisfy(\.isAvailable))
        XCTAssertTrue(categoryOptions.allSatisfy(\.showsValue))
        XCTAssertTrue(categoryOptions.allSatisfy { $0.defaultValue == inventoryDefaultValue })
        XCTAssertTrue(categoryOptions.allSatisfy { $0.unavailableReason == nil })
        XCTAssertTrue(categoryOptions.allSatisfy(\.isMomentary))
    }

    func testCurrencyOptionsUseMomentaryIncrementActions() {
        let featureIDs = Set(SimpleTrainerOptions.currencies.compactMap(incrementFeatureID))

        XCTAssertEqual(featureIDs, ["gold", "bei", "jungleGold"])
        XCTAssertTrue(SimpleTrainerOptions.currencies.allSatisfy(\.isMomentary))
        XCTAssertTrue(SimpleTrainerOptions.currencies.allSatisfy(\.showsValue))
    }

    func testDivingOptionsExposeCrabTrapPatch() throws {
        let option = try option(withID: "crabTraps", in: SimpleTrainerOptions.diving)

        XCTAssertEqual(option.action, .patch(patchID: "crabTraps"))
        XCTAssertFalse(option.isMomentary)
        XCTAssertFalse(option.showsValue)
        XCTAssertEqual(option.defaultValue, "1")
    }

    func testJungleInventoryOptionUsesMomentaryIncrementAction() throws {
        let option = try option(withID: "jungleIngredients", in: SimpleTrainerOptions.inventory)

        XCTAssertEqual(option.action, .incrementJungleInventory(scope: .ingredientsAndVillageItems))
        XCTAssertTrue(option.isMomentary)
        XCTAssertTrue(option.showsValue)
        XCTAssertEqual(option.defaultValue, inventoryDefaultValue)
    }

    func testSeaPeopleVillageItemsOptionUsesVillageOnlyScope() throws {
        let option = try option(withID: "seaPeopleVillageItems", in: SimpleTrainerOptions.inventory)

        XCTAssertEqual(option.action, .incrementJungleInventory(scope: .villageItems))
        XCTAssertEqual(option.manifestFeatureID, "seaPeopleVillageItems")
        XCTAssertTrue(option.isMomentary)
        XCTAssertTrue(option.showsValue)
        XCTAssertEqual(option.defaultValue, inventoryDefaultValue)
    }

    func testSushiBarQuantityOptionUsesMomentaryIncrementAction() throws {
        let artisanOption = try option(withID: "artisan", in: SimpleTrainerOptions.sushiBar)

        XCTAssertEqual(incrementFeatureID(artisanOption), "artisan")
        XCTAssertTrue(artisanOption.isMomentary)
        XCTAssertTrue(artisanOption.showsValue)
    }

    private func option(withID id: String, in options: [SimpleTrainerOption]) throws -> SimpleTrainerOption {
        try XCTUnwrap(options.first { $0.id == id })
    }

    private func incrementFeatureID(_ option: SimpleTrainerOption) -> String? {
        if case .increment(let featureID) = option.action {
            return featureID
        }
        return nil
    }

    private func inventoryIncrementScopeID(_ option: SimpleTrainerOption) -> String? {
        if case .incrementInventory(let scope) = option.action {
            switch scope {
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
        return nil
    }
}
