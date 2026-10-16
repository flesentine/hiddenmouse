import XCTest
@testable import ParkHunt

final class MultiParkSupportTests: XCTestCase {
    func testParkCatalogDiscoversAndOrdersUnknownThirdPark() {
        let snapshot = makeSnapshot()

        let parks = ParkCatalog.options(in: snapshot)

        XCTAssertEqual(
            parks.map(\.id),
            [
                "disneyland",
                "disney-california-adventure",
                "third-resort"
            ]
        )
        XCTAssertEqual(
            parks.map(\.name),
            [
                "Disneyland",
                "Disney California Adventure",
                "Third Resort"
            ]
        )
        XCTAssertEqual(
            ParkCatalog.defaultParkID(in: snapshot),
            "disneyland"
        )
    }

    func testCollectionCanFilterToCatalogOnlyThirdPark() {
        let snapshot = makeSnapshot()
        let collection = CollectionSnapshot.make(
            snapshot: snapshot,
            progress: UserProgress(),
            filters: CollectionFilters(
                parkID: "third-resort"
            )
        )

        XCTAssertEqual(
            collection.items.map { $0.discovery.id },
            ["third-hunt"]
        )
        XCTAssertEqual(
            collection.lands.map(\.id),
            ["third-land"]
        )
    }

    func testTodayRouteStaysInsideCatalogOnlyThirdPark() {
        let snapshot = makeSnapshot()
        let route = TodayRouteBuilder.build(
            snapshot: snapshot,
            progress: UserProgress(),
            length: .short,
            parkID: "third-resort"
        )

        XCTAssertEqual(
            route.items.map { $0.discovery.parkID },
            ["third-resort"]
        )
    }

    func testMapPresentationScopesToCatalogOnlyThirdPark() {
        let snapshot = makeSnapshot()
        let presentation = ParkMapPresentation.make(
            snapshot: snapshot,
            progress: UserProgress(),
            parkID: "third-resort"
        )

        XCTAssertEqual(presentation.mappedCount, 1)
        XCTAssertEqual(
            presentation.points.map(\.discoveryID),
            ["third-hunt"]
        )
    }

    func testManualBrowseUsesSameParkCatalogOrdering() {
        let snapshot = makeSnapshot()

        XCTAssertEqual(
            ManualAreaPresentation.parks(from: snapshot)
                .map(\.id),
            ParkCatalog.options(in: snapshot).map(\.id)
        )
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
            sortOrder: 101
        )
        let third = Land(
            id: "third-land",
            parkID: "third-resort",
            name: "Third Land",
            sortOrder: 201
        )

        return ContentSnapshot(
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: [third, dca, disneyland],
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
                    ),
                    makeDiscovery(
                        id: "third-hunt",
                        parkID: "third-resort",
                        landID: third.id,
                        longitude: -117.90
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
