import XCTest
@testable import ParkHunt

final class SettingsStoreTests: XCTestCase {
    func testHapticsDefaultToEnabled() {
        let suiteName = "ParkHuntTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsHapticPreferenceStore(
            defaults: defaults,
            storageKey: "haptics"
        )

        XCTAssertTrue(store.load())
    }

    func testHapticPreferenceRoundTrips() {
        let suiteName = "ParkHuntTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsHapticPreferenceStore(
            defaults: defaults,
            storageKey: "haptics"
        )

        store.save(false)

        XCTAssertFalse(store.load())
    }

    func testMemoryProgressStoreResetClearsOnlyProgress() {
        var progress = UserProgress()
        progress.recordFound(
            discoveryID: "secret",
            at: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let store = MemoryUserProgressStore(progress: progress)

        store.reset()

        XCTAssertEqual(store.load(), UserProgress())
    }

    func testUserDefaultsProgressResetRemovesStoredProgress() {
        let suiteName = "ParkHuntTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsUserProgressStore(
            defaults: defaults,
            storageKey: "progress"
        )
        var progress = UserProgress()
        progress.recordFound(
            discoveryID: "secret",
            at: Date(timeIntervalSince1970: 1_700_000_000)
        )
        store.save(progress)

        store.reset()

        XCTAssertEqual(store.load(), UserProgress())
    }
}
