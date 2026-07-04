import XCTest
@testable import TrainerCore

final class RuntimeAddressCacheKeyTests: XCTestCase {
    func testRuntimeAddressCacheKeySeparatesProcessBuildModuleAndFeature() {
        let base = RuntimeAddressCacheKey(
            processID: 100,
            buildFingerprint: "build-a",
            moduleBaseAddress: 0x1000,
            moduleIdentity: "GameAssembly.uuid-a",
            featureID: "gold"
        )

        XCTAssertNotEqual(base, RuntimeAddressCacheKey(processID: 101, buildFingerprint: "build-a", moduleBaseAddress: 0x1000, moduleIdentity: "GameAssembly.uuid-a", featureID: "gold"))
        XCTAssertNotEqual(base, RuntimeAddressCacheKey(processID: 100, buildFingerprint: "build-b", moduleBaseAddress: 0x1000, moduleIdentity: "GameAssembly.uuid-a", featureID: "gold"))
        XCTAssertNotEqual(base, RuntimeAddressCacheKey(processID: 100, buildFingerprint: "build-a", moduleBaseAddress: 0x2000, moduleIdentity: "GameAssembly.uuid-a", featureID: "gold"))
        XCTAssertNotEqual(base, RuntimeAddressCacheKey(processID: 100, buildFingerprint: "build-a", moduleBaseAddress: 0x1000, moduleIdentity: "GameAssembly.uuid-b", featureID: "gold"))
        XCTAssertNotEqual(base, RuntimeAddressCacheKey(processID: 100, buildFingerprint: "build-a", moduleBaseAddress: 0x1000, moduleIdentity: "GameAssembly.uuid-a", featureID: "bei"))
    }
}
