import XCTest
@testable import ParkHunt

final class DiscoverySelectorTests: XCTestCase {
    func testDefaultSelectionReturnsFirstUnfoundResult() {
        let results = [
            makeResult(id: "found-first", isFound: true),
            makeResult(id: "unfound-second", isFound: false),
            makeResult(id: "unfound-third", isFound: false)
        ]

        let selected = DiscoverySelector.select(from: results)

        XCTAssertEqual(selected?.discovery.id, "unfound-second")
    }

    func testDefaultSelectionReturnsNilWhenEverythingIsFound() {
        let results = [
            makeResult(id: "one", isFound: true),
            makeResult(id: "two", isFound: true)
        ]

        XCTAssertNil(DiscoverySelector.select(from: results))
    }

    func testCompletedCanBeExplicitlyIncludedAsFallback() {
        let results = [
            makeResult(id: "one", isFound: true),
            makeResult(id: "two", isFound: true)
        ]

        let selected = DiscoverySelector.select(
            from: results,
            request: DiscoverySelectionRequest(
                completedPolicy: .includeIfNeeded
            )
        )

        XCTAssertEqual(selected?.discovery.id, "one")
    }

    func testUnfoundStillWinsWhenCompletedFallbackIsAllowed() {
        let results = [
            makeResult(id: "found", isFound: true),
            makeResult(id: "unfound", isFound: false)
        ]

        let selected = DiscoverySelector.select(
            from: results,
            request: DiscoverySelectionRequest(
                completedPolicy: .includeIfNeeded
            )
        )

        XCTAssertEqual(selected?.discovery.id, "unfound")
    }

    func testCurrentDiscoveryIsNeverImmediatelyRepeated() {
        let results = [
            makeResult(id: "current", isFound: false),
            makeResult(id: "next", isFound: false)
        ]

        let selected = DiscoverySelector.select(
            from: results,
            request: DiscoverySelectionRequest(
                currentDiscoveryID: "current"
            )
        )

        XCTAssertEqual(selected?.discovery.id, "next")
    }

    func testExcludedDiscoveriesAreSkipped() {
        let results = [
            makeResult(id: "skip-a", isFound: false),
            makeResult(id: "skip-b", isFound: false),
            makeResult(id: "keep", isFound: false)
        ]

        let selected = DiscoverySelector.select(
            from: results,
            request: DiscoverySelectionRequest(
                excludedDiscoveryIDs: ["skip-a", "skip-b"]
            )
        )

        XCTAssertEqual(selected?.discovery.id, "keep")
    }

    func testSelectionPreservesRankedOrder() {
        let results = [
            makeResult(id: "rank-one", isFound: false),
            makeResult(id: "rank-two", isFound: false)
        ]

        XCTAssertEqual(
            DiscoverySelector.select(from: results)?.discovery.id,
            "rank-one"
        )
    }

    func testEngineConvenienceSelectionUsesProgress() {
        let snapshot = makeSnapshot()
        let progress = UserProgress(
            discoveries: [
                "first": DiscoveryProgress(
                    discoveryID: "first",
                    foundAt: Date()
                )
            ]
        )

        let selected = DiscoverySelector.select(
            snapshot: snapshot,
            context: NearbyDiscoveryContext(landID: "land"),
            filters: NearbyDiscoveryFilters(scope: .land("land")),
            progress: progress
        )

        XCTAssertEqual(selected?.discovery.id, "second")
    }

    func testCompletedFallbackStillHonorsCurrentAndExcludedDiscoveries() {
        let results = [
            makeResult(id: "current", isFound: true),
            makeResult(id: "excluded", isFound: true),
            makeResult(id: "eligible", isFound: true)
        ]

        let selected = DiscoverySelector.select(
            from: results,
            request: DiscoverySelectionRequest(
                currentDiscoveryID: "current",
                excludedDiscoveryIDs: ["excluded"],
                completedPolicy: .includeIfNeeded
            )
        )

        XCTAssertEqual(selected?.discovery.id, "eligible")
    }

    func testSelectionReturnsNilWhenEveryCandidateIsExcluded() {
        let results = [
            makeResult(id: "one", isFound: false),
            makeResult(id: "two", isFound: false)
        ]

        let selected = DiscoverySelector.select(
            from: results,
            request: DiscoverySelectionRequest(
                excludedDiscoveryIDs: ["one", "two"],
                completedPolicy: .includeIfNeeded
            )
        )

        XCTAssertNil(selected)
    }

    private func makeResult(
        id: String,
        isFound: Bool
    ) -> NearbyDiscoveryResult {
        NearbyDiscoveryResult(
            discovery: makeDiscovery(id: id),
            distanceMeters: nil,
            isFound: isFound,
            matchesPark: true,
            matchesLand: true,
            matchesArea: true
        )
    }

    private func makeSnapshot() -> ContentSnapshot {
        let land = Land(
            id: "land",
            parkID: "park",
            name: "Land",
            sortOrder: 1
        )

        return ContentSnapshot(
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: [land],
                areas: [],
                discoveries: [
                    makeDiscovery(id: "first"),
                    makeDiscovery(id: "second")
                ]
            )
        )
    }

    private func makeDiscovery(id: String) -> Discovery {
        Discovery(
            id: id,
            title: id,
            parkID: "park",
            landID: "land",
            areaID: nil,
            category: .hiddenMickey,
            difficulty: .easy,
            location: nil,
            hints: [
                Hint(id: "\(id)-h1", order: 1, text: "Look nearby.")
            ],
            revealDescription: "Reveal.",
            revealImageName: nil,
            verificationStatus: .verified,
            lastVerifiedAt: nil,
            isIndoor: false,
            tags: []
        )
    }
}
