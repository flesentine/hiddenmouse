import XCTest
@testable import ParkHunt

final class HuntPresentationTests: XCTestCase {
    func testPresentationLoadsContext() {
        let snapshot = makeSnapshot()

        let presentation = HuntPresentation.make(
            discoveryID: "secret",
            snapshot: snapshot
        )

        XCTAssertEqual(presentation?.discovery.id, "secret")
        XCTAssertEqual(presentation?.landName, "New Orleans Square")
        XCTAssertEqual(
            presentation?.areaName,
            "Pirates of the Caribbean"
        )
        XCTAssertEqual(
            presentation?.locationText,
            "New Orleans Square · Pirates of the Caribbean"
        )
    }

    func testPresentationHandlesLandWithoutArea() {
        let snapshot = makeSnapshot(areaID: nil)

        let presentation = HuntPresentation.make(
            discoveryID: "secret",
            snapshot: snapshot
        )

        XCTAssertEqual(
            presentation?.locationText,
            "New Orleans Square"
        )
    }

    func testUnavailableDiscoveryDoesNotCreateHunt() {
        let snapshot = makeSnapshot(status: .removed)

        XCTAssertNil(
            HuntPresentation.make(
                discoveryID: "secret",
                snapshot: snapshot
            )
        )
    }

    func testMissingDiscoveryDoesNotCreateHunt() {
        let snapshot = makeSnapshot()

        XCTAssertNil(
            HuntPresentation.make(
                discoveryID: "missing",
                snapshot: snapshot
            )
        )
    }

    func testCategoryDisplayNamesAreGuestFacing() {
        XCTAssertEqual(
            DiscoveryCategory.hiddenMickey.displayName,
            "Hidden Mickey"
        )
        XCTAssertEqual(
            DiscoveryCategory.imagineeringDetail.displayName,
            "Imagineering Detail"
        )
        XCTAssertEqual(
            DiscoveryCategory.easterEgg.displayName,
            "Easter Egg"
        )
    }

    private func makeSnapshot(
        areaID: String? = "pirates",
        status: VerificationStatus = .verified
    ) -> ContentSnapshot {
        let land = Land(
            id: "new-orleans-square",
            parkID: "disneyland",
            name: "New Orleans Square",
            sortOrder: 1
        )
        let area = AttractionArea(
            id: "pirates",
            landID: land.id,
            name: "Pirates of the Caribbean",
            kind: .attraction,
            sortOrder: 1
        )
        let discovery = Discovery(
            id: "secret",
            title: "Prototype Secret",
            parkID: "disneyland",
            landID: land.id,
            areaID: areaID,
            category: .hiddenMickey,
            difficulty: .medium,
            location: nil,
            hints: [
                Hint(id: "first", order: 1, text: "First clue")
            ],
            revealDescription: "Reveal.",
            revealImageName: nil,
            verificationStatus: status,
            lastVerifiedAt: nil,
            isIndoor: false,
            tags: []
        )

        return ContentSnapshot(
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: [land],
                areas: [area],
                discoveries: [discovery]
            )
        )
    }
}
