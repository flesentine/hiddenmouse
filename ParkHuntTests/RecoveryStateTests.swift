import XCTest
@testable import ParkHunt

final class RecoveryStateTests: XCTestCase {
    func testAvailabilityDistinguishesEmptyAvailableAndComplete() {
        XCTAssertEqual(
            HuntAvailabilityState.make(results: []),
            .noneAvailable
        )

        XCTAssertEqual(
            HuntAvailabilityState.make(
                results: [
                    makeResult(id: "a", found: false),
                    makeResult(id: "b", found: true)
                ]
            ),
            .available
        )

        XCTAssertEqual(
            HuntAvailabilityState.make(
                results: [
                    makeResult(id: "a", found: true),
                    makeResult(id: "b", found: true)
                ]
            ),
            .allComplete
        )
    }

    func testMissingOfflineAssetsGetSpecificRecoveryCopy() {
        let recovery = CatalogRecoveryPresentation.make(
            error: ContentStoreError.offlineReadinessFailed(
                [
                    .missingRevealImage(
                        discoveryID: "secret",
                        imageName: "missing.jpg"
                    )
                ]
            )
        )

        XCTAssertEqual(recovery.kind, .missingAssets)
        XCTAssertEqual(recovery.title, "Offline Content Incomplete")
        XCTAssertTrue(recovery.message.contains("required offline assets"))
    }

    func testInvalidCatalogGetsSpecificRecoveryCopy() {
        let recovery = CatalogRecoveryPresentation.make(
            error: ContentStoreError.validationFailed([])
        )

        XCTAssertEqual(recovery.kind, .invalidContent)
        XCTAssertEqual(recovery.title, "Offline Content Invalid")
    }

    func testUnknownErrorFallsBackToGenericRecovery() {
        struct UnknownError: Error {}

        let recovery = CatalogRecoveryPresentation.make(
            error: UnknownError()
        )

        XCTAssertEqual(recovery.kind, .unavailable)
        XCTAssertEqual(recovery.title, "Couldn’t Load Offline Content")
    }

    private func makeResult(
        id: String,
        found: Bool
    ) -> NearbyDiscoveryResult {
        NearbyDiscoveryResult(
            discovery: Discovery(
                id: id,
                title: id,
                parkID: "park",
                landID: "land",
                areaID: nil,
                category: .secretFeature,
                difficulty: .easy,
                location: nil,
                hints: [
                    Hint(id: "\(id)-h1", order: 1, text: "Look.")
                ],
                revealDescription: "Reveal.",
                revealImageName: nil,
                verificationStatus: .verified,
                lastVerifiedAt: nil,
                isIndoor: false,
                tags: []
            ),
            distanceMeters: nil,
            isFound: found,
            matchesPark: true,
            matchesLand: true,
            matchesArea: false
        )
    }
}
