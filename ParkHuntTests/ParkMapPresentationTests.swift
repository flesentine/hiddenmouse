import XCTest
@testable import ParkHunt

final class ParkMapPresentationTests: XCTestCase {
    func testPresentationIncludesOnlyDiscoveriesWithLocations() {
        let mapped = makeDiscovery(id: "mapped", hasLocation: true)
        let unmapped = makeDiscovery(id: "unmapped", hasLocation: false)
        let snapshot = ContentSnapshot(
            catalog: makeCatalog(discoveries: [mapped, unmapped])
        )

        let presentation = ParkMapPresentation.make(
            snapshot: snapshot,
            progress: UserProgress()
        )

        XCTAssertEqual(presentation.points.map(\.discoveryID), ["mapped"])
        XCTAssertEqual(presentation.mappedCount, 1)
        XCTAssertEqual(presentation.unmappedCount, 1)
    }

    func testPresentationCarriesFoundState() {
        let discovery = makeDiscovery(id: "mapped", hasLocation: true)
        let snapshot = ContentSnapshot(
            catalog: makeCatalog(discoveries: [discovery])
        )
        var progress = UserProgress()
        progress.recordFound(discoveryID: "mapped")

        let presentation = ParkMapPresentation.make(
            snapshot: snapshot,
            progress: progress
        )

        XCTAssertEqual(presentation.points.first?.isFound, true)
    }

    func testRealCatalogDoesNotInventScaleBatchPins() throws {
        let snapshot = try ContentLoader().load()
        let presentation = ParkMapPresentation.make(
            snapshot: snapshot,
            progress: UserProgress()
        )

        XCTAssertEqual(presentation.mappedCount, 18)
        XCTAssertEqual(presentation.unmappedCount, 57)
        XCTAssertTrue(
            presentation.points.allSatisfy { point in
                snapshot.discovery(id: point.discoveryID)?.location != nil
            }
        )
    }

    private func makeCatalog(
        discoveries: [Discovery]
    ) -> ContentCatalog {
        ContentCatalog(
            schemaVersion: ContentCatalog.currentSchemaVersion,
            lands: [
                Land(
                    id: "land",
                    parkID: "park",
                    name: "Land",
                    sortOrder: 1
                )
            ],
            areas: [],
            discoveries: discoveries
        )
    }

    private func makeDiscovery(
        id: String,
        hasLocation: Bool
    ) -> Discovery {
        Discovery(
            id: id,
            title: id.capitalized,
            parkID: "park",
            landID: "land",
            areaID: nil,
            category: .imagineeringDetail,
            difficulty: .easy,
            location: hasLocation
                ? DiscoveryLocation(
                    latitude: 33.81,
                    longitude: -117.92,
                    radiusMeters: 75
                )
                : nil,
            hints: [
                Hint(id: "\(id)-h1", order: 1, text: "Look."),
                Hint(id: "\(id)-h2", order: 2, text: "Look closer."),
                Hint(
                    id: "\(id)-h3",
                    order: 3,
                    text: "Here.",
                    kind: .detailed
                )
            ],
            revealDescription: "Reveal.",
            revealImageName: nil,
            verificationStatus: .needsRecheck,
            lastVerifiedAt: nil,
            isIndoor: false,
            tags: []
        )
    }
}
