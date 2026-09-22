import XCTest
@testable import ParkHunt

final class OfflineReadinessTests: XCTestCase {
    func testCatalogWithoutRevealImagesIsOfflineReady() {
        let snapshot = ContentSnapshot(
            catalog: makeCatalog(revealImageName: nil)
        )

        let issues = OfflineReadinessValidator.validate(
            snapshot: snapshot,
            imageExists: { _ in false }
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testReferencedRevealImageMustBePackaged() {
        let snapshot = ContentSnapshot(
            catalog: makeCatalog(
                revealImageName: "missing-reference"
            )
        )

        let issues = OfflineReadinessValidator.validate(
            snapshot: snapshot,
            imageExists: { _ in false }
        )

        XCTAssertEqual(
            issues,
            [
                .missingRevealImage(
                    discoveryID: "secret",
                    imageName: "missing-reference"
                )
            ]
        )
    }

    func testReferencedRevealImagePassesWhenAvailableLocally() {
        let snapshot = ContentSnapshot(
            catalog: makeCatalog(
                revealImageName: "reference"
            )
        )

        let issues = OfflineReadinessValidator.validate(
            snapshot: snapshot,
            imageExists: { $0 == "reference" }
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testContentLoaderRejectsMissingPackagedImage() {
        let loader = ContentLoader(
            source: StubContentSource(
                catalog: makeCatalog(
                    revealImageName: "missing-reference"
                )
            ),
            revealImageStore: BundledRevealImageStore(
                bundle: Bundle(for: Self.self)
            )
        )

        XCTAssertThrowsError(try loader.load()) { error in
            XCTAssertEqual(
                error as? ContentStoreError,
                .offlineReadinessFailed(
                    [
                        .missingRevealImage(
                            discoveryID: "secret",
                            imageName: "missing-reference"
                        )
                    ]
                )
            )
        }
    }

    func testRealBundledCatalogIsOfflineReady() throws {
        let snapshot = try ContentLoader().load()

        XCTAssertFalse(snapshot.discoveries.isEmpty)
    }

    private func makeCatalog(
        revealImageName: String?
    ) -> ContentCatalog {
        ContentCatalog(
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
            discoveries: [
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
                            id: "secret-h1",
                            order: 1,
                            text: "Look nearby."
                        )
                    ],
                    revealDescription: "Reveal.",
                    revealImageName: revealImageName,
                    verificationStatus: .verified,
                    lastVerifiedAt: nil,
                    isIndoor: false,
                    tags: []
                )
            ]
        )
    }
}

private struct StubContentSource: ContentCatalogSource {
    let catalog: ContentCatalog

    func loadCatalog() throws -> ContentCatalog {
        catalog
    }
}
