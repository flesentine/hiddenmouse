import XCTest
@testable import ParkHunt

final class TodayRouteBuilderTests: XCTestCase {
    func testRoutePrefersUnfinishedHunts() {
        let snapshot = makeSnapshot(
            landCounts: [("land-a", 5), ("land-b", 2)]
        )
        var progress = UserProgress()
        progress.recordFound(discoveryID: "land-a-0")

        let route = TodayRouteBuilder.build(
            snapshot: snapshot,
            progress: progress,
            length: .short
        )

        XCTAssertEqual(route.items.count, 3)
        XCTAssertFalse(route.items.contains { $0.discovery.id == "land-a-0" })
    }

    func testRouteStaysInOneLandWhenEnoughHuntsExist() {
        let snapshot = makeSnapshot(
            landCounts: [("land-a", 6), ("land-b", 2)]
        )

        let route = TodayRouteBuilder.build(
            snapshot: snapshot,
            progress: UserProgress(),
            length: .medium
        )

        XCTAssertEqual(route.items.count, 5)
        XCTAssertEqual(Set(route.items.map { $0.discovery.landID }), ["land-a"])
        XCTAssertEqual(route.focusLandName, "Land A")
    }

    func testRouteFallsBackAcrossLandsWhenNeeded() {
        let snapshot = makeSnapshot(
            landCounts: [("land-a", 2), ("land-b", 2)]
        )

        let route = TodayRouteBuilder.build(
            snapshot: snapshot,
            progress: UserProgress(),
            length: .medium
        )

        XCTAssertEqual(route.items.count, 4)
        XCTAssertEqual(Set(route.items.map { $0.discovery.landID }).count, 2)
        XCTAssertNil(route.focusLandName)
    }

    func testAllFoundStillBuildsAReplayRoute() {
        let snapshot = makeSnapshot(
            landCounts: [("land-a", 3)]
        )
        var progress = UserProgress()
        for index in 0..<3 {
            progress.recordFound(discoveryID: "land-a-\(index)")
        }

        let route = TodayRouteBuilder.build(
            snapshot: snapshot,
            progress: progress,
            length: .short
        )

        XCTAssertEqual(route.items.count, 3)
        XCTAssertTrue(route.items.allSatisfy(\.isFound))
        XCTAssertTrue(route.isComplete)
    }

    private func makeSnapshot(
        landCounts: [(String, Int)]
    ) -> ContentSnapshot {
        let lands = landCounts.enumerated().map { index, item in
            Land(
                id: item.0,
                parkID: "park",
                name: "Land \(Character(UnicodeScalar(65 + index)!))",
                sortOrder: index + 1
            )
        }

        var discoveries: [Discovery] = []
        for (landID, count) in landCounts {
            for index in 0..<count {
                let id = "\(landID)-\(index)"
                discoveries.append(
                    Discovery(
                        id: id,
                        title: "Hunt \(index)",
                        parkID: "park",
                        landID: landID,
                        areaID: nil,
                        category: .imagineeringDetail,
                        difficulty: index % 2 == 0 ? .easy : .medium,
                        location: nil,
                        hints: [Hint(id: "\(id)-h1", order: 1, text: "Look.")],
                        revealDescription: "Reveal.",
                        revealImageName: nil,
                        verificationStatus: .needsRecheck,
                        lastVerifiedAt: nil,
                        isIndoor: false,
                        tags: []
                    )
                )
            }
        }

        return ContentSnapshot(
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: lands,
                areas: [],
                discoveries: discoveries
            )
        )
    }
}
