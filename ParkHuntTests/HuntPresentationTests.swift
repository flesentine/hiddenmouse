import XCTest
@testable import ParkHunt

final class HuntPresentationTests: XCTestCase {
    func testPresentationLoadsContextAndFirstSortedHint() {
        let snapshot = makeSnapshot(
            hints: [
                Hint(id: "second", order: 2, text: "Second clue"),
                Hint(id: "first", order: 1, text: "First clue")
            ]
        )

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
        XCTAssertEqual(presentation?.firstHint?.id, "first")
        XCTAssertEqual(presentation?.cluePositionText, "Clue 1 of 2")
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

    func testMissingHintHasNoCluePosition() {
        let snapshot = makeSnapshot(hints: [])

        let presentation = HuntPresentation.make(
            discoveryID: "secret",
            snapshot: snapshot
        )

        XCTAssertNil(presentation?.firstHint)
        XCTAssertNil(presentation?.cluePositionText)
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
        hints: [Hint] = [
            Hint(id: "first", order: 1, text: "First clue")
        ],
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
            hints: hints,
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
