import XCTest
@testable import ParkHunt

final class UserProgressPersistenceTests: XCTestCase {
    func testHintProgressOnlyMovesForward() {
        let firstDate = Date(timeIntervalSince1970: 1_700_000_000)
        let secondDate = firstDate.addingTimeInterval(60)
        var progress = UserProgress()

        progress.recordHintViewed(
            discoveryID: "secret",
            order: 3,
            at: firstDate
        )
        progress.recordHintViewed(
            discoveryID: "secret",
            order: 2,
            at: secondDate
        )

        let saved = progress.progress(for: "secret")

        XCTAssertEqual(saved.highestHintOrderViewed, 3)
        XCTAssertEqual(saved.lastViewedAt, secondDate)
        XCTAssertEqual(progress.lastUpdatedAt, secondDate)
    }

    func testRevealIsPersistedWithoutMarkingFound() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        var progress = UserProgress()

        progress.recordRevealViewed(
            discoveryID: "secret",
            at: date
        )

        let saved = progress.progress(for: "secret")

        XCTAssertTrue(saved.didRevealLocation)
        XCTAssertFalse(saved.isFound)
        XCTAssertEqual(saved.lastViewedAt, date)
    }

    func testUserDefaultsStoreRoundTripsProgress() throws {
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
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        var progress = UserProgress()
        progress.recordHintViewed(
            discoveryID: "secret",
            order: 2,
            at: date
        )
        progress.recordRevealViewed(
            discoveryID: "secret",
            at: date
        )

        store.save(progress)

        XCTAssertEqual(store.load(), progress)
    }

    func testCorruptStoredProgressFallsBackToEmpty() throws {
        let suiteName = "ParkHuntTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set(
            Data("not-json".utf8),
            forKey: "progress"
        )

        let store = UserDefaultsUserProgressStore(
            defaults: defaults,
            storageKey: "progress"
        )

        XCTAssertEqual(store.load(), UserProgress())
    }
}
