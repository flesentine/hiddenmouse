import XCTest
@testable import ParkHunt

final class PrivacyImplementationTests: XCTestCase {
    func testAnalyticsPreferenceDefaultsToEnabled() {
        let suiteName = "ParkHuntTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsAnalyticsPreferenceStore(
            defaults: defaults,
            storageKey: "analytics-enabled"
        )

        XCTAssertTrue(store.load())
    }

    func testAnalyticsPreferenceRoundTrips() {
        let store = MemoryAnalyticsPreferenceStore()

        store.save(false)
        XCTAssertFalse(store.load())

        store.save(true)
        XCTAssertTrue(store.load())
    }

    func testDisabledAnalyticsStopsNewEventsWithoutDeletingExistingData() {
        let preference = MemoryAnalyticsPreferenceStore(
            isEnabled: true
        )
        let now = Date(timeIntervalSince1970: 10_000)
        let recorder = MemoryAnalyticsRecorder(
            preferenceStore: preference,
            nowProvider: { now }
        )

        recorder.record(.appOpen(at: now))
        preference.save(false)
        recorder.record(.appOpen(at: now))

        XCTAssertEqual(recorder.events().count, 1)
    }

    func testAnalyticsOlderThanThirtyDaysArePruned() {
        let now = Date(timeIntervalSince1970: 4_000_000)
        let old = now.addingTimeInterval(
            -(31 * 24 * 60 * 60)
        )
        let recent = now.addingTimeInterval(
            -(5 * 24 * 60 * 60)
        )

        let recorder = MemoryAnalyticsRecorder(
            events: [
                .appOpen(at: old),
                .appOpen(at: recent)
            ],
            nowProvider: { now }
        )

        XCTAssertEqual(
            recorder.events().map(\.timestamp),
            [recent]
        )
    }

    func testClearingAnalyticsDoesNotChangePreference() {
        let preference = MemoryAnalyticsPreferenceStore(
            isEnabled: false
        )
        let recorder = MemoryAnalyticsRecorder(
            events: [
                .appOpen(
                    at: Date()
                )
            ],
            preferenceStore: preference
        )

        recorder.clear()

        XCTAssertTrue(recorder.events().isEmpty)
        XCTAssertFalse(preference.load())
    }

    func testUserDefaultsRecorderPrunesExpiredEventsPersistently() {
        let suiteName = "ParkHuntTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let preference = MemoryAnalyticsPreferenceStore()
        let now = Date(timeIntervalSince1970: 5_000_000)
        let recorder = UserDefaultsAnalyticsRecorder(
            defaults: defaults,
            storageKey: "analytics",
            preferenceStore: preference,
            nowProvider: { now }
        )

        recorder.record(
            .appOpen(
                at: now.addingTimeInterval(
                    -(31 * 24 * 60 * 60)
                )
            )
        )
        recorder.record(
            .appOpen(at: now)
        )

        XCTAssertEqual(recorder.events().count, 1)
    }
}
