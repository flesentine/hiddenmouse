import XCTest
@testable import ParkHunt

final class NearbyDiscoveryEngineTests: XCTestCase {
    func testAreaAndLandMatchesRankAheadOfOtherParkDiscoveries() {
        let snapshot = makeSnapshot()
        let fix = makeFix()

        let results = NearbyDiscoveryEngine.results(
            snapshot: snapshot,
            context: NearbyDiscoveryContext(
                parkID: "park",
                landID: "land-a",
                areaID: "area-a",
                locationFix: fix
            ),
            filters: NearbyDiscoveryFilters(scope: .park("park"))
        )

        XCTAssertEqual(
            results.map(\.discovery.id),
            ["area-match", "land-match", "other-land"]
        )
    }

    func testUnfoundRanksAheadOfFoundWithinSameContext() {
        let snapshot = makeSnapshot(
            discoveries: [
                makeDiscovery(id: "found", latitude: 33.81191),
                makeDiscovery(id: "unfound", latitude: 33.81192)
            ]
        )
        let foundAt = Date(timeIntervalSince1970: 1_700_000_000)
        let progress = UserProgress(
            discoveries: [
                "found": DiscoveryProgress(
                    discoveryID: "found",
                    foundAt: foundAt
                )
            ]
        )

        let results = NearbyDiscoveryEngine.results(
            snapshot: snapshot,
            context: NearbyDiscoveryContext(
                parkID: "park",
                landID: "land-a",
                areaID: "area-a",
                locationFix: makeFix()
            ),
            progress: progress
        )

        XCTAssertEqual(results.map(\.discovery.id), ["unfound", "found"])
        XCTAssertFalse(results[0].isFound)
        XCTAssertTrue(results[1].isFound)
    }

    func testDistanceBreaksTiesBeforeDifficulty() {
        let snapshot = makeSnapshot(
            discoveries: [
                makeDiscovery(
                    id: "far-easy",
                    difficulty: .easy,
                    latitude: 33.8130
                ),
                makeDiscovery(
                    id: "near-hard",
                    difficulty: .hard,
                    latitude: 33.81191
                )
            ]
        )

        let results = NearbyDiscoveryEngine.results(
            snapshot: snapshot,
            context: NearbyDiscoveryContext(
                landID: "land-a",
                areaID: "area-a",
                locationFix: makeFix()
            )
        )

        XCTAssertEqual(results.map(\.discovery.id), ["near-hard", "far-easy"])
    }

    func testDifficultyBreaksTieWhenDistanceIsUnknown() {
        let snapshot = makeSnapshot(
            discoveries: [
                makeDiscovery(id: "hard", difficulty: .hard, latitude: nil),
                makeDiscovery(id: "easy", difficulty: .easy, latitude: nil)
            ]
        )

        let results = NearbyDiscoveryEngine.results(
            snapshot: snapshot,
            context: NearbyDiscoveryContext(landID: "land-a")
        )

        XCTAssertEqual(results.map(\.discovery.id), ["easy", "hard"])
    }

    func testFiltersLandDifficultyFoundAndDistance() {
        let snapshot = makeSnapshot(
            discoveries: [
                makeDiscovery(
                    id: "keep",
                    difficulty: .medium,
                    latitude: 33.81191
                ),
                makeDiscovery(
                    id: "wrong-difficulty",
                    difficulty: .hard,
                    latitude: 33.81191
                ),
                makeDiscovery(
                    id: "too-far",
                    difficulty: .medium,
                    latitude: 33.8200
                ),
                makeDiscovery(
                    id: "other-land",
                    landID: "land-b",
                    areaID: "area-b",
                    difficulty: .medium,
                    latitude: 33.81191
                )
            ]
        )

        let results = NearbyDiscoveryEngine.results(
            snapshot: snapshot,
            context: NearbyDiscoveryContext(locationFix: makeFix()),
            filters: NearbyDiscoveryFilters(
                scope: .land("land-a"),
                difficulties: [.medium],
                found: .unfound,
                maximumDistanceMeters: 300
            )
        )

        XCTAssertEqual(results.map(\.discovery.id), ["keep"])
    }

    func testFoundFilterCanReturnOnlyFound() {
        let snapshot = makeSnapshot(
            discoveries: [
                makeDiscovery(id: "found"),
                makeDiscovery(id: "unfound")
            ]
        )
        let progress = UserProgress(
            discoveries: [
                "found": DiscoveryProgress(
                    discoveryID: "found",
                    foundAt: Date()
                )
            ]
        )

        let results = NearbyDiscoveryEngine.results(
            snapshot: snapshot,
            filters: NearbyDiscoveryFilters(found: .found),
            progress: progress
        )

        XCTAssertEqual(results.map(\.discovery.id), ["found"])
    }

    func testUnavailableDiscoveriesNeverEnterEngine() {
        let snapshot = makeSnapshot(
            discoveries: [
                makeDiscovery(id: "ready", status: .verified),
                makeDiscovery(id: "removed", status: .removed),
                makeDiscovery(
                    id: "temporary",
                    status: .temporarilyUnavailable
                )
            ]
        )

        let results = NearbyDiscoveryEngine.results(snapshot: snapshot)

        XCTAssertEqual(results.map(\.discovery.id), ["ready"])
    }

    private func makeSnapshot(
        discoveries: [Discovery]? = nil
    ) -> ContentSnapshot {
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
        let areaA = AttractionArea(
            id: "area-a",
            landID: "land-a",
            name: "Area A",
            kind: .area,
            sortOrder: 1
        )
        let areaB = AttractionArea(
            id: "area-b",
            landID: "land-b",
            name: "Area B",
            kind: .area,
            sortOrder: 1
        )

        let defaultDiscoveries = [
            makeDiscovery(id: "area-match", latitude: 33.8130),
            makeDiscovery(
                id: "land-match",
                areaID: nil,
                latitude: 33.81191
            ),
            makeDiscovery(
                id: "other-land",
                landID: "land-b",
                areaID: "area-b",
                latitude: 33.81191
            )
        ]

        return ContentSnapshot(
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: [landA, landB],
                areas: [areaA, areaB],
                discoveries: discoveries ?? defaultDiscoveries
            )
        )
    }

    private func makeDiscovery(
        id: String,
        landID: String = "land-a",
        areaID: String? = "area-a",
        difficulty: Difficulty = .medium,
        latitude: Double? = 33.8119,
        status: VerificationStatus = .verified
    ) -> Discovery {
        Discovery(
            id: id,
            title: id,
            parkID: "park",
            landID: landID,
            areaID: areaID,
            category: .hiddenMickey,
            difficulty: difficulty,
            location: latitude.map {
                DiscoveryLocation(
                    latitude: $0,
                    longitude: -117.9190,
                    radiusMeters: 100
                )
            },
            hints: [
                Hint(id: "\(id)-h1", order: 1, text: "Look nearby.")
            ],
            revealDescription: "Reveal.",
            revealImageName: nil,
            verificationStatus: status,
            lastVerifiedAt: nil,
            isIndoor: false,
            tags: []
        )
    }

    private func makeFix() -> LocationFix {
        LocationFix(
            latitude: 33.8119,
            longitude: -117.9190,
            horizontalAccuracyMeters: 20,
            timestamp: Date()
        )
    }
}
