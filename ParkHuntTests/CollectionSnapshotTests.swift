import XCTest
@testable import ParkHunt

final class CollectionSnapshotTests: XCTestCase {
    func testDefaultCollectionIncludesAllHuntableDiscoveries() {
        let collection = CollectionSnapshot.make(
            snapshot: makeSnapshot(),
            progress: makeProgress()
        )

        XCTAssertEqual(
            collection.items.map(\.discovery.id),
            ["a-found", "a-started", "b-unstarted", "b-found"]
        )
        XCTAssertEqual(collection.items.count, 4)
        XCTAssertFalse(
            collection.items.contains {
                $0.discovery.id == "removed"
            }
        )
    }

    func testFoundFilterReturnsOnlyCompletedDiscoveries() {
        let collection = CollectionSnapshot.make(
            snapshot: makeSnapshot(),
            progress: makeProgress(),
            filters: CollectionFilters(status: .found)
        )

        XCTAssertEqual(
            collection.items.map(\.discovery.id),
            ["a-found", "b-found"]
        )
    }

    func testUnfoundFilterIncludesStartedAndUnstarted() {
        let collection = CollectionSnapshot.make(
            snapshot: makeSnapshot(),
            progress: makeProgress(),
            filters: CollectionFilters(status: .unfound)
        )

        XCTAssertEqual(
            collection.items.map(\.discovery.id),
            ["a-started", "b-unstarted"]
        )
    }

    func testStartedFilterExcludesFoundAndUntouched() {
        let collection = CollectionSnapshot.make(
            snapshot: makeSnapshot(),
            progress: makeProgress(),
            filters: CollectionFilters(status: .started)
        )

        XCTAssertEqual(
            collection.items.map(\.discovery.id),
            ["a-started"]
        )
    }

    func testLandAndCategoryFiltersCompose() {
        let collection = CollectionSnapshot.make(
            snapshot: makeSnapshot(),
            progress: makeProgress(),
            filters: CollectionFilters(
                landID: "land-b",
                category: .secretFeature
            )
        )

        XCTAssertEqual(
            collection.items.map(\.discovery.id),
            ["b-found"]
        )
    }

    func testCollectionStateCarriesFoundAndLastViewedDates() {
        let progress = makeProgress()
        let collection = CollectionSnapshot.make(
            snapshot: makeSnapshot(),
            progress: progress
        )

        let found = collection.items.first {
            $0.discovery.id == "a-found"
        }
        let started = collection.items.first {
            $0.discovery.id == "a-started"
        }

        XCTAssertEqual(found?.progressState, .found)
        XCTAssertEqual(found?.foundAt, date(100))
        XCTAssertEqual(started?.progressState, .started)
        XCTAssertEqual(started?.lastViewedAt, date(200))
    }

    func testAvailableLandAndCategoryFiltersComeFromCurrentCatalog() {
        let collection = CollectionSnapshot.make(
            snapshot: makeSnapshot(),
            progress: UserProgress()
        )

        XCTAssertEqual(
            collection.lands.map(\.id),
            ["land-a", "land-b"]
        )
        XCTAssertEqual(
            Set(collection.categories),
            Set([.hiddenMickey, .secretFeature])
        )
    }

    private func makeProgress() -> UserProgress {
        UserProgress(
            discoveries: [
                "a-found": DiscoveryProgress(
                    discoveryID: "a-found",
                    highestHintOrderViewed: 1,
                    foundAt: date(100),
                    lastViewedAt: date(100)
                ),
                "a-started": DiscoveryProgress(
                    discoveryID: "a-started",
                    highestHintOrderViewed: 1,
                    lastViewedAt: date(200)
                ),
                "b-found": DiscoveryProgress(
                    discoveryID: "b-found",
                    foundAt: date(300),
                    lastViewedAt: date(300)
                )
            ],
            lastUpdatedAt: date(300)
        )
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
                        id: "a-found",
                        title: "A Found",
                        landID: "land-a",
                        category: .hiddenMickey
                    ),
                    makeDiscovery(
                        id: "a-started",
                        title: "B Started",
                        landID: "land-a",
                        category: .secretFeature
                    ),
                    makeDiscovery(
                        id: "b-unstarted",
                        title: "A Unstarted",
                        landID: "land-b",
                        category: .hiddenMickey
                    ),
                    makeDiscovery(
                        id: "b-found",
                        title: "B Found",
                        landID: "land-b",
                        category: .secretFeature
                    ),
                    makeDiscovery(
                        id: "removed",
                        title: "Removed",
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
        title: String,
        landID: String,
        category: DiscoveryCategory,
        status: VerificationStatus = .verified
    ) -> Discovery {
        Discovery(
            id: id,
            title: title,
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
