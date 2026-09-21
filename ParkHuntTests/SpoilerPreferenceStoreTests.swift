import XCTest
@testable import ParkHunt

final class SpoilerPreferenceStoreTests: XCTestCase {
    func testDefaultPreferenceIsNormal() {
        let suiteName = "ParkHuntTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsSpoilerPreferenceStore(
            defaults: defaults,
            storageKey: "spoiler"
        )

        XCTAssertEqual(store.load(), .normal)
    }

    func testPreferenceRoundTripsThroughUserDefaults() {
        let suiteName = "ParkHuntTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsSpoilerPreferenceStore(
            defaults: defaults,
            storageKey: "spoiler"
        )

        store.save(.helpMe)

        XCTAssertEqual(store.load(), .helpMe)
    }

    func testUnknownStoredValueFallsBackToNormal() {
        let suiteName = "ParkHuntTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set("future-mode", forKey: "spoiler")

        let store = UserDefaultsSpoilerPreferenceStore(
            defaults: defaults,
            storageKey: "spoiler"
        )

        XCTAssertEqual(store.load(), .normal)
    }
}
