import XCTest
@testable import ParkHunt

final class MultiParkSupportTests: XCTestCase {
    func testParkCatalogReturnsDisneylandThenDCA() {
        let snapshot = makeSnapshot()

        XCTAssertEqual(
            ParkCatalog.options(in: snapshot).map(\.id),
            ["disneyland", "disney-california-adventure"]
        )
    }

    func testCollectionCanFilterToDCA() {
        let snapshot = makeSnapshot()
        let collection = CollectionSnapshot.make(
            snapshot: snapshot,
            progress: UserProgress(),
            filters: CollectionFilters(
                parkID: "disney-california-adventure"
            )
        )

        XCTAssertEqual(collection.items.map { $0.discovery.id }, ["dca-hunt"])
        XCTAssertEqual(collection.lands.map(\.id), ["dca-land"])
    }

    func testTodayRouteStaysInsideSelectedPark() {
        let snapshot = makeSnapshot()
        let route = TodayRouteBuilder.build(
            snapshot: snapshot,
            progress: UserProgress(),
            length: .short,
            parkID: "disney-california-adventure"
        )

        XCTAssertEqual(route.items.map { $0.discovery.parkID }, ["disney-california-adventure"])
    }

    func testMapPresentationScopesToSelectedPark() {
        let snapshot = makeSnapshot()
        let presentation = ParkMapPresentation.make(
            snapshot: snapshot,
            progress: UserProgress(),
            parkID: "disney-california-adventure"
        )

        XCTAssertEqual(presentation.mappedCount, 1)
        XCTAssertEqual(presentation.points.map(\.discoveryID), ["dca-hunt"])
    }

    private func makeSnapshot() -> ContentSnapshot {
        let disneyland = Land(
            id: "dl-land",
            parkID: "disneyland",
            name: "Disneyland Land",
            sortOrder: 1
        )
        let dca = Land(
            id: "dca-land",
            parkID: "disney-california-adventure",
            name: "DCA Land",
            sortOrder: 1
        )

        return ContentSnapshot(
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: [disneyland, dca],
                areas: [],
                discoveries: [
                    makeDiscovery(
                        id: "dl-hunt",
                        parkID: "disneyland",
                        landID: disneyland.id,
                        longitude: -117.92
                    ),
                    makeDiscovery(
                        id: "dca-hunt",
                        parkID: "disney-california-adventure",
                        landID: dca.id,
                        longitude: -117.91
                    )
                ]
            )
        )
    }

    private func makeDiscovery(
        id: String,
        parkID: String,
        landID: String,
        longitude: Double
    ) -> Discovery {
        Discovery(
            id: id,
            title: id,
            parkID: parkID,
            landID: landID,
            areaID: nil,
            category: .imagineeringDetail,
            difficulty: .easy,
            location: DiscoveryLocation(
                latitude: 33.81,
                longitude: longitude,
                radiusMeters: 75
            ),
            hints: [
                Hint(id: "\(id)-h1", order: 1, text: "Look.")
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
