import XCTest
@testable import ParkHunt

final class FieldTestFeedbackTests: XCTestCase {
    func testRecordNormalizesIssuesAndNotes() {
        let record = FieldTestFeedbackRecord(
            discoveryID: "hunt-1",
            discoveryTitle: "Test Hunt",
            accuracy: .accurate,
            clueQuality: .clear,
            nearbyUsefulness: .useful,
            issues: [.other, .locationWrong, .other],
            notes: "  Needs another look.  "
        )

        XCTAssertEqual(record.issues, [.locationWrong, .other])
        XCTAssertEqual(record.notes, "Needs another look.")
    }

    func testUserDefaultsStoreRoundTripsAndClears() throws {
        let suite = "FieldTestFeedbackTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = UserDefaultsFieldTestFeedbackStore(
            defaults: defaults,
            storageKey: "feedback"
        )
        let record = FieldTestFeedbackRecord(
            timestamp: Date(timeIntervalSince1970: 100),
            discoveryID: "hunt-1",
            discoveryTitle: "Test Hunt",
            accuracy: .close,
            clueQuality: .workable,
            nearbyUsefulness: .okay,
            issues: [.clueConfusing],
            notes: "Reword clue two."
        )

        store.save(record)

        XCTAssertEqual(store.records(), [record])

        store.clear()
        XCTAssertTrue(store.records().isEmpty)
    }

    func testStoreCapsOldestRecords() throws {
        let suite = "FieldTestFeedbackTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = UserDefaultsFieldTestFeedbackStore(
            defaults: defaults,
            storageKey: "feedback",
            maximumRecordCount: 2
        )

        for index in 1...3 {
            store.save(
                FieldTestFeedbackRecord(
                    timestamp: Date(timeIntervalSince1970: TimeInterval(index)),
                    discoveryID: "hunt-\(index)",
                    discoveryTitle: "Hunt \(index)",
                    accuracy: .accurate,
                    clueQuality: .clear,
                    nearbyUsefulness: .notUsed
                )
            )
        }

        XCTAssertEqual(
            store.records().map(\.discoveryID),
            ["hunt-3", "hunt-2"]
        )
    }
}
