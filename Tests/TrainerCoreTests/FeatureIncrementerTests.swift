import XCTest
@testable import TrainerCore

final class FeatureIncrementerTests: XCTestCase {
    func testIncrementInt32AddressAddsDeltaOnce() throws {
        let session = MachMemoryAccess().currentProcessSession()
        var value = Int32(40)
        let address = UInt64(UInt(bitPattern: withUnsafeMutablePointer(to: &value) { $0 }))
        let feature = TrainerFeature(descriptor: TrainerFeatureDescriptor(
            identity: TrainerFeatureIdentity(id: "materials", title: "材料数量"),
            behavior: TrainerFeatureBehavior(mode: .setValue, valueKind: .int32),
            requiredBuild: KnownGameBuild.current
        ))
        let book = AddressBook(build: KnownGameBuild.current, entries: [
            "materials": AddressEntry(
                featureID: "materials",
                details: AddressEntryDetails(address: address, valueKind: .int32, note: "test")
            )
        ])

        let result = try FeatureIncrementer().increment(
            FeatureIncrementRequest(feature: feature, delta: 9, addressBook: book),
            session: session
        )

        XCTAssertEqual(result.previous.intValue, 40)
        XCTAssertEqual(result.next.intValue, 49)
        XCTAssertEqual(value, 49)
    }

    func testNegativeInt32DeltaClampsQuantityToOne() throws {
        let session = MachMemoryAccess().currentProcessSession()
        var value = Int32(40)
        let address = UInt64(UInt(bitPattern: withUnsafeMutablePointer(to: &value) { $0 }))
        let feature = TrainerFeature(descriptor: TrainerFeatureDescriptor(
            identity: TrainerFeatureIdentity(id: "materials", title: "材料数量"),
            behavior: TrainerFeatureBehavior(mode: .setValue, valueKind: .int32),
            requiredBuild: KnownGameBuild.current
        ))
        let book = AddressBook(build: KnownGameBuild.current, entries: [
            "materials": AddressEntry(
                featureID: "materials",
                details: AddressEntryDetails(address: address, valueKind: .int32, note: "test")
            )
        ])

        let result = try FeatureIncrementer().increment(
            FeatureIncrementRequest(feature: feature, delta: -99, addressBook: book),
            session: session
        )

        XCTAssertEqual(result.previous.intValue, 40)
        XCTAssertEqual(result.next.intValue, 1)
        XCTAssertEqual(value, 1)
    }

    func testIncrementInt64AddressAddsDeltaOnce() throws {
        let session = MachMemoryAccess().currentProcessSession()
        var value = Int64(10_000)
        let address = UInt64(UInt(bitPattern: withUnsafeMutablePointer(to: &value) { $0 }))
        let feature = TrainerFeature(descriptor: TrainerFeatureDescriptor(
            identity: TrainerFeatureIdentity(id: "gold", title: "金币"),
            behavior: TrainerFeatureBehavior(mode: .setValue, valueKind: .int64),
            requiredBuild: KnownGameBuild.current
        ))
        let book = AddressBook(build: KnownGameBuild.current, entries: [
            "gold": AddressEntry(
                featureID: "gold",
                details: AddressEntryDetails(address: address, valueKind: .int64, note: "test")
            )
        ])

        let result = try FeatureIncrementer().increment(
            FeatureIncrementRequest(feature: feature, delta: 99_999, addressBook: book),
            session: session
        )

        XCTAssertEqual(result.previous.intValue, 10_000)
        XCTAssertEqual(result.next.intValue, 109_999)
        XCTAssertEqual(value, 109_999)
    }

    func testNegativeInt64DeltaClampsQuantityToOne() throws {
        let session = MachMemoryAccess().currentProcessSession()
        var value = Int64(10_000)
        let address = UInt64(UInt(bitPattern: withUnsafeMutablePointer(to: &value) { $0 }))
        let feature = TrainerFeature(descriptor: TrainerFeatureDescriptor(
            identity: TrainerFeatureIdentity(id: "gold", title: "金币"),
            behavior: TrainerFeatureBehavior(mode: .setValue, valueKind: .int64),
            requiredBuild: KnownGameBuild.current
        ))
        let book = AddressBook(build: KnownGameBuild.current, entries: [
            "gold": AddressEntry(
                featureID: "gold",
                details: AddressEntryDetails(address: address, valueKind: .int64, note: "test")
            )
        ])

        let result = try FeatureIncrementer().increment(
            FeatureIncrementRequest(feature: feature, delta: -99_999, addressBook: book),
            session: session
        )

        XCTAssertEqual(result.previous.intValue, 10_000)
        XCTAssertEqual(result.next.intValue, 1)
        XCTAssertEqual(value, 1)
    }

    func testIncrementInt32RejectsOverflow() throws {
        let session = MachMemoryAccess().currentProcessSession()
        var value = Int32.max
        let address = UInt64(UInt(bitPattern: withUnsafeMutablePointer(to: &value) { $0 }))
        let feature = TrainerFeature(descriptor: TrainerFeatureDescriptor(
            identity: TrainerFeatureIdentity(id: "materials", title: "材料数量"),
            behavior: TrainerFeatureBehavior(mode: .setValue, valueKind: .int32),
            requiredBuild: KnownGameBuild.current
        ))
        let book = AddressBook(build: KnownGameBuild.current, entries: [
            "materials": AddressEntry(
                featureID: "materials",
                details: AddressEntryDetails(address: address, valueKind: .int32, note: "test")
            )
        ])

        XCTAssertThrowsError(try FeatureIncrementer().increment(
            FeatureIncrementRequest(feature: feature, delta: 1, addressBook: book),
            session: session
        ))
        XCTAssertEqual(value, Int32.max)
    }
}
