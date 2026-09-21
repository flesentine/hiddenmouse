import XCTest
@testable import ParkHunt

final class FoundProgressTests: XCTestCase {
    func testRecordFoundPersistsCompletionTimestamp() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        var progress = UserProgress()

        progress.recordFound(
            discoveryID: "secret",
            at: date
        )

        let saved = progress.progress(for: "secret")

        XCTAssertTrue(saved.isFound)
        XCTAssertEqual(saved.foundAt, date)
        XCTAssertEqual(saved.lastViewedAt, date)
        XCTAssertEqual(progress.lastUpdatedAt, date)
        XCTAssertTrue(progress.foundDiscoveryIDs.contains("secret"))
    }

    func testRecordFoundIsIdempotentAndPreservesFirstCompletionTime() {
        let first = Date(timeIntervalSince1970: 1_700_000_000)
        let later = first.addingTimeInterval(3_600)
        var progress = UserProgress()

        progress.recordFound(
            discoveryID: "secret",
            at: first
        )
        progress.recordFound(
            discoveryID: "secret",
            at: later
        )

        let saved = progress.progress(for: "secret")

        XCTAssertEqual(saved.foundAt, first)
        XCTAssertEqual(saved.lastViewedAt, first)
        XCTAssertEqual(progress.lastUpdatedAt, first)
    }

    func testFoundProgressRoundTripsThroughStore() {
        let store = MemoryUserProgressStore()
        var progress = UserProgress()
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        progress.recordFound(
            discoveryID: "secret",
            at: date
        )
        store.save(progress)

        XCTAssertEqual(
            store.load().progress(for: "secret").foundAt,
            date
        )
    }
}
