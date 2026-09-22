import XCTest
@testable import ParkHunt

final class DiscoveryImageCodingTests: XCTestCase {
    func testOlderJSONWithoutThumbnailRemainsCompatible() throws {
        let json = """
        {
          "id": "secret",
          "title": "Secret",
          "parkID": "park",
          "landID": "land",
          "category": "secretFeature",
          "difficulty": "easy",
          "hints": [
            {
              "id": "h1",
              "order": 1,
              "text": "Look nearby."
            }
          ],
          "revealDescription": "Reveal.",
          "verificationStatus": "verified",
          "isIndoor": false,
          "tags": []
        }
        """

        let discovery = try JSONDecoder().decode(
            Discovery.self,
            from: Data(json.utf8)
        )

        XCTAssertNil(discovery.thumbnailImageName)
        XCTAssertNil(discovery.revealImageName)
    }

    func testThumbnailAndRevealNamesRoundTrip() throws {
        let discovery = makeDiscovery(
            thumbnailImageName: "secret-thumb.jpg",
            revealImageName: "secret-reveal.jpg"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let roundTripped = try decoder.decode(
            Discovery.self,
            from: encoder.encode(discovery)
        )

        XCTAssertEqual(
            roundTripped.thumbnailImageName,
            "secret-thumb.jpg"
        )
        XCTAssertEqual(
            roundTripped.revealImageName,
            "secret-reveal.jpg"
        )
    }

    func testOfflineReadinessChecksThumbnailAndRevealSeparately() {
        let discovery = makeDiscovery(
            thumbnailImageName: "secret-thumb.jpg",
            revealImageName: "secret-reveal.jpg"
        )
        let snapshot = ContentSnapshot(
            catalog: ContentCatalog(
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
                discoveries: [discovery]
            )
        )

        let issues = OfflineReadinessValidator.validate(
            snapshot: snapshot,
            imageExists: {
                $0 == "secret-reveal.jpg"
            }
        )

        XCTAssertEqual(
            issues,
            [
                .missingThumbnailImage(
                    discoveryID: "secret",
                    imageName: "secret-thumb.jpg"
                )
            ]
        )
    }

    private func makeDiscovery(
        thumbnailImageName: String?,
        revealImageName: String?
    ) -> Discovery {
        Discovery(
            id: "secret",
            title: "Secret",
            parkID: "park",
            landID: "land",
            areaID: nil,
            category: .secretFeature,
            difficulty: .easy,
            location: nil,
            hints: [
                Hint(
                    id: "h1",
                    order: 1,
                    text: "Look nearby."
                )
            ],
            revealDescription: "Reveal.",
            revealImageName: revealImageName,
            thumbnailImageName: thumbnailImageName,
            verificationStatus: .verified,
            lastVerifiedAt: nil,
            isIndoor: false,
            tags: []
        )
    }
}
