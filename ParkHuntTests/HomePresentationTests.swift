import XCTest
@testable import ParkHunt

final class HomePresentationTests: XCTestCase {
    func testPresentationUsesFirstSortedLandAndItsAvailableDiscoveries() {
        let catalog = ContentCatalog(
            schemaVersion: ContentCatalog.currentSchemaVersion,
            lands: [
                Land(id: "second", parkID: "park", name: "Second", sortOrder: 2),
                Land(id: "first", parkID: "park", name: "First", sortOrder: 1)
            ],
            areas: [],
            discoveries: [
                makeDiscovery(id: "other", landID: "second", status: .verified),
                makeDiscovery(id: "removed", landID: "first", status: .removed),
                makeDiscovery(id: "ready", landID: "first", status: .verified)
            ]
        )

        let presentation = HomePresentation.make(
            from: ContentSnapshot(catalog: catalog)
        )

        XCTAssertEqual(presentation.landName, "First")
        XCTAssertEqual(presentation.discoveryCount, 1)
        XCTAssertEqual(presentation.primaryDiscoveryID, "ready")
        XCTAssertEqual(presentation.primaryDiscoveryTitle, "Secret ready")
        XCTAssertEqual(presentation.primaryDifficulty, .easy)
        XCTAssertEqual(presentation.discoveryCountText, "1 discovery ready")
    }

    func testPresentationHandlesEmptyCatalog() {
        let catalog = ContentCatalog(
            schemaVersion: ContentCatalog.currentSchemaVersion,
            lands: [],
            areas: [],
            discoveries: []
        )

        let presentation = HomePresentation.make(
            from: ContentSnapshot(catalog: catalog)
        )

        XCTAssertEqual(presentation.landName, "Disneyland")
        XCTAssertEqual(presentation.discoveryCount, 0)
        XCTAssertNil(presentation.primaryDiscoveryID)
        XCTAssertEqual(presentation.discoveryCountText, "No discoveries ready")
    }

    func testDiscoveryCountTextPluralizes() {
        let presentation = HomePresentation(
            landName: "Land",
            discoveryCount: 3,
            primaryDiscoveryID: "one",
            primaryDiscoveryTitle: "One",
            primaryDifficulty: .medium
        )

        XCTAssertEqual(presentation.discoveryCountText, "3 discoveries ready")
    }

    private func makeDiscovery(
        id: String,
        landID: String,
        status: VerificationStatus
    ) -> Discovery {
        Discovery(
            id: id,
            title: "Secret \(id)",
            parkID: "park",
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
