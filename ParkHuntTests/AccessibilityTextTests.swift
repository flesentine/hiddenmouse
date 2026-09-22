import XCTest
@testable import ParkHunt

final class AccessibilityTextTests: XCTestCase {
    func testNearbyVoiceOverLabelIncludesStatusDifficultyAreaAndDistance() {
        let discovery = makeDiscovery(
            id: "secret",
            difficulty: .hard
        )
        let result = NearbyDiscoveryResult(
            discovery: discovery,
            distanceMeters: 125,
            isFound: true,
            matchesPark: true,
            matchesLand: true,
            matchesArea: true
        )

        XCTAssertEqual(
            ParkHuntAccessibility.nearbyResult(
                result,
                areaName: "Pirates"
            ),
            "Secret, Found, Hard difficulty, Pirates, about 130 m away"
        )
    }

    func testCollectionVoiceOverLabelDoesNotDependOnColorOrIcon() {
        let item = CollectionItem(
            discovery: makeDiscovery(
                id: "secret",
                difficulty: .easy
            ),
            landName: "New Orleans Square",
            areaName: "Pirates",
            progressState: .started,
            foundAt: nil,
            lastViewedAt: nil
        )

        let label = ParkHuntAccessibility.collectionItem(item)

        XCTAssertTrue(label.contains("Started"))
        XCTAssertTrue(label.contains("Easy difficulty"))
        XCTAssertTrue(label.contains("New Orleans Square"))
    }

    func testHintVoiceOverLabelIncludesPositionAndText() {
        XCTAssertEqual(
            ParkHuntAccessibility.hint(
                title: "First Clue",
                position: "Clue 1 of 2",
                text: "Look above the arch."
            ),
            "First Clue. Clue 1 of 2. Look above the arch."
        )
    }

    func testProgressVoiceOverLabelIncludesNumericMeaning() {
        XCTAssertEqual(
            ParkHuntAccessibility.progress(
                title: "Adventureland",
                found: 3,
                total: 7
            ),
            "Adventureland, 3 of 7 found"
        )
    }

    private func makeDiscovery(
        id: String,
        difficulty: Difficulty
    ) -> Discovery {
        Discovery(
            id: id,
            title: "Secret",
            parkID: "park",
            landID: "land",
            areaID: nil,
            category: .secretFeature,
            difficulty: difficulty,
            location: nil,
            hints: [
                Hint(id: "h1", order: 1, text: "Look.")
            ],
            revealDescription: "Reveal.",
            revealImageName: nil,
            verificationStatus: .verified,
            lastVerifiedAt: nil,
            isIndoor: false,
            tags: []
        )
    }
}
