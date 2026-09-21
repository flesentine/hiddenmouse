import XCTest
@testable import ParkHunt

final class RevealPresentationTests: XCTestCase {
    func testRevealPresentationUsesDiscoveryRevealAndContext() {
        let snapshot = makeSnapshot(
            revealImageName: "reference-photo"
        )

        let presentation = RevealPresentation.make(
            discoveryID: "secret",
            snapshot: snapshot
        )

        XCTAssertEqual(
            presentation?.exactLocationText,
            "Look above the left side of the arch."
        )
        XCTAssertEqual(
            presentation?.contextText,
            "New Orleans Square · Pirates of the Caribbean"
        )
        XCTAssertEqual(
            presentation?.referenceImageName,
            "reference-photo"
        )
    }

    func testRevealPresentationSupportsMissingReferencePhoto() {
        let snapshot = makeSnapshot(revealImageName: nil)

        let presentation = RevealPresentation.make(
            discoveryID: "secret",
            snapshot: snapshot
        )

        XCTAssertNil(presentation?.referenceImageName)
    }

    func testUnavailableDiscoveryHasNoRevealPresentation() {
        let snapshot = makeSnapshot(
            revealImageName: nil,
            status: .removed
        )

        XCTAssertNil(
            RevealPresentation.make(
                discoveryID: "secret",
                snapshot: snapshot
            )
        )
    }

    private func makeSnapshot(
        revealImageName: String?,
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
            title: "Secret",
            parkID: "disneyland",
            landID: land.id,
            areaID: area.id,
            category: .secretFeature,
            difficulty: .easy,
            location: nil,
            hints: [
                Hint(id: "h1", order: 1, text: "Look nearby.")
            ],
            revealDescription: "Look above the left side of the arch.",
            revealImageName: revealImageName,
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
