import XCTest
@testable import ParkHunt

final class ProgressSummaryTests: XCTestCase {
    func testOverallCountsOnlyCurrentHuntableDiscoveries() {
        let snapshot = makeSnapshot()
        var progress = UserProgress()
        progress.recordHintViewed(
            discoveryID: "a1",
            order: 1,
            at: date(100)
        )
        progress.recordFound(
            discoveryID: "a1",
            at: date(200)
        )
        progress.recordHintViewed(
            discoveryID: "a2",
            order: 1,
            at: date(300)
        )
        progress.recordFound(
            discoveryID: "removed",
            at: date(400)
        )

        let summary = ProgressSummary.make(
            snapshot: snapshot,
            progress: progress
        )

        XCTAssertEqual(summary.overall.total, 4)
        XCTAssertEqual(summary.overall.started, 2)
        XCTAssertEqual(summary.overall.found, 1)
        XCTAssertEqual(summary.overall.remaining, 3)
        XCTAssertEqual(summary.overall.completionFraction, 0.25)
    }

    func testLandProgressUsesCurrentCatalogAssignments() {
        let snapshot = makeSnapshot()
        var progress = UserProgress()
        progress.recordFound(
            discoveryID: "a1",
            at: date(100)
        )
        progress.recordFound(
            discoveryID: "b1",
            at: date(200)
        )

        let summary = ProgressSummary.make(
            snapshot: snapshot,
            progress: progress
        )

        XCTAssertEqual(
            summary.lands.map(\.id),
            ["land-a", "land-b"]
        )
        XCTAssertEqual(summary.lands[0].count.total, 2)
        XCTAssertEqual(summary.lands[0].count.found, 1)
        XCTAssertEqual(summary.lands[1].count.total, 2)
        XCTAssertEqual(summary.lands[1].count.found, 1)
    }

    func testCategoryProgressGroupsAvailableDiscoveries() {
        let snapshot = makeSnapshot()
        var progress = UserProgress()
        progress.recordFound(
            discoveryID: "a1",
            at: date(100)
        )
        progress.recordFound(
            discoveryID: "b2",
            at: date(200)
        )

        let summary = ProgressSummary.make(
            snapshot: snapshot,
            progress: progress
        )

        let hiddenMickey = summary.categories.first {
            $0.category == .hiddenMickey
        }
        let secretFeature = summary.categories.first {
            $0.category == .secretFeature
        }

        XCTAssertEqual(hiddenMickey?.count.total, 2)
        XCTAssertEqual(hiddenMickey?.count.found, 1)
        XCTAssertEqual(secretFeature?.count.total, 2)
        XCTAssertEqual(secretFeature?.count.found, 1)
    }

    func testRecentActivityAndRecentFoundAreIndependent() {
        let snapshot = makeSnapshot()
        var progress = UserProgress()
        progress.recordFound(
            discoveryID: "a1",
            at: date(100)
        )
        progress.recordHintViewed(
            discoveryID: "b1",
            order: 1,
            at: date(300)
        )

        let summary = ProgressSummary.make(
            snapshot: snapshot,
            progress: progress
        )

        XCTAssertEqual(
            summary.recentFound?.discoveryID,
            "a1"
        )
        XCTAssertEqual(
            summary.recentFound?.foundAt,
            date(100)
        )
        XCTAssertEqual(
            summary.recentActivity?.discoveryID,
            "b1"
        )
        XCTAssertEqual(
            summary.recentActivity?.lastViewedAt,
            date(300)
        )
    }

    func testLastUpdatedAtComesFromPersistedProgress() {
        let snapshot = makeSnapshot()
        var progress = UserProgress()
        progress.recordHintViewed(
            discoveryID: "a1",
            order: 1,
            at: date(500)
        )

        let summary = ProgressSummary.make(
            snapshot: snapshot,
            progress: progress
        )

        XCTAssertEqual(summary.lastUpdatedAt, date(500))
    }

    func testEmptyProgressStillReportsCatalogTotals() {
        let summary = ProgressSummary.make(
            snapshot: makeSnapshot(),
            progress: UserProgress()
        )

        XCTAssertEqual(summary.overall.total, 4)
        XCTAssertEqual(summary.overall.started, 0)
        XCTAssertEqual(summary.overall.found, 0)
        XCTAssertNil(summary.recentActivity)
        XCTAssertNil(summary.recentFound)
    }

    private func makeSnapshot() -> ContentSnapshot {
        let landA = Land(
            id: "land-a",
            parkID: "park",
            name: "Land A",
            sortOrder: 1
        )
        let landB = Land(
            id: "land-b",
            parkID: "park",
            name: "Land B",
            sortOrder: 2
        )

        return ContentSnapshot(
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: [landA, landB],
                areas: [],
                discoveries: [
                    makeDiscovery(
                        id: "a1",
                        landID: "land-a",
                        category: .hiddenMickey
                    ),
                    makeDiscovery(
                        id: "a2",
                        landID: "land-a",
                        category: .secretFeature
                    ),
                    makeDiscovery(
                        id: "b1",
                        landID: "land-b",
                        category: .hiddenMickey
                    ),
                    makeDiscovery(
                        id: "b2",
                        landID: "land-b",
                        category: .secretFeature
                    ),
                    makeDiscovery(
                        id: "removed",
                        landID: "land-a",
                        category: .hiddenMickey,
                        status: .removed
                    )
                ]
            )
        )
    }

    private func makeDiscovery(
        id: String,
        landID: String,
        category: DiscoveryCategory,
        status: VerificationStatus = .verified
    ) -> Discovery {
        Discovery(
            id: id,
            title: id,
            parkID: "park",
            landID: landID,
            areaID: nil,
            category: category,
            difficulty: .easy,
            location: nil,
            hints: [
                Hint(id: "\(id)-h1", order: 1, text: "Look.")
            ],
            revealDescription: "Reveal.",
            revealImageName: nil,
            verificationStatus: status,
            lastVerifiedAt: nil,
            isIndoor: false,
            tags: []
        )
    }

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }
}
