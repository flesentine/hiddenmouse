import XCTest
@testable import ParkHunt

final class ManualAreaPresentationTests: XCTestCase {
    func testParkOptionsAreDerivedFromCatalog() {
        let snapshot = makeSnapshot()

        let parks = ManualAreaPresentation.parks(from: snapshot)

        XCTAssertEqual(parks.count, 2)
        XCTAssertEqual(parks.map(\.name), ["Disneyland", "Second Park"])

        let disneyland = parks.first { $0.id == "disneyland" }
        XCTAssertEqual(disneyland?.landCount, 2)
        XCTAssertEqual(disneyland?.discoveryCount, 2)
    }

    func testLandOptionsUseCatalogSortOrderAndAvailableCounts() {
        let snapshot = makeSnapshot()

        let lands = ManualAreaPresentation.lands(
            inPark: "disneyland",
            snapshot: snapshot
        )

        XCTAssertEqual(lands.map(\.id), ["first-land", "second-land"])
        XCTAssertEqual(lands.map(\.discoveryCount), [1, 1])
    }

    func testRemovedDiscoveriesDoNotCountAsReady() {
        let snapshot = makeSnapshot()

        let lands = ManualAreaPresentation.lands(
            inPark: "disneyland",
            snapshot: snapshot
        )

        XCTAssertEqual(
            lands.first { $0.id == "first-land" }?.discoveryCount,
            1
        )
    }

    func testDiscoveryCountTextPluralizes() {
        XCTAssertEqual(
            ManualAreaPresentation.discoveryCountText(0),
            "No hunts ready"
        )
        XCTAssertEqual(
            ManualAreaPresentation.discoveryCountText(1),
            "1 hunt ready"
        )
        XCTAssertEqual(
            ManualAreaPresentation.discoveryCountText(3),
            "3 hunts ready"
        )
    }

    private func makeSnapshot() -> ContentSnapshot {
        let firstLand = Land(
            id: "first-land",
            parkID: "disneyland",
            name: "First Land",
            sortOrder: 1
        )
        let secondLand = Land(
            id: "second-land",
            parkID: "disneyland",
            name: "Second Land",
            sortOrder: 2
        )
        let otherParkLand = Land(
            id: "other-land",
            parkID: "second-park",
            name: "Other Land",
            sortOrder: 1
        )

        return ContentSnapshot(
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: [secondLand, otherParkLand, firstLand],
                areas: [],
                discoveries: [
                    makeDiscovery(
                        id: "first-ready",
                        landID: firstLand.id,
                        status: .verified
                    ),
                    makeDiscovery(
                        id: "first-removed",
                        landID: firstLand.id,
                        status: .removed
                    ),
                    makeDiscovery(
                        id: "second-ready",
                        landID: secondLand.id,
                        status: .verified
                    ),
                    makeDiscovery(
                        id: "other-ready",
                        parkID: "second-park",
                        landID: otherParkLand.id,
                        status: .verified
                    )
                ]
            )
        )
    }

    private func makeDiscovery(
        id: String,
        parkID: String = "disneyland",
        landID: String,
        status: VerificationStatus
    ) -> Discovery {
        Discovery(
            id: id,
            title: id,
            parkID: parkID,
            landID: landID,
            areaID: nil,
            category: .hiddenMickey,
            difficulty: .easy,
            location: nil,
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
}
