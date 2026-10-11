import XCTest
@testable import ParkHunt

final class RemoteContentTests: XCTestCase {
    func testUnavailableRemoteFallsBackToBundledCatalog() throws {
        let bundled = StaticContentSource(
            catalog: makeCatalog(id: "bundled")
        )
        let source = RemoteFallbackContentSource(
            bundled: bundled,
            fetcher: MemoryRemoteContentFetcher(
                package: nil,
                isAvailable: false
            ),
            verifier: MemoryRemoteContentVerifier()
        )

        let catalog = try source.loadCatalog()

        XCTAssertEqual(catalog.discoveries.first?.id, "bundled")
        XCTAssertEqual(source.selection, .bundled)
    }

    func testUntrustedRemoteFallsBackToBundledCatalog() throws {
        let remote = try package(
            revision: 2,
            catalog: makeCatalog(id: "remote")
        )
        let source = RemoteFallbackContentSource(
            bundled: StaticContentSource(
                catalog: makeCatalog(id: "bundled")
            ),
            fetcher: MemoryRemoteContentFetcher(
                package: remote
            ),
            verifier: MemoryRemoteContentVerifier(
                trustedRevisions: []
            )
        )

        let catalog = try source.loadCatalog()

        XCTAssertEqual(catalog.discoveries.first?.id, "bundled")
        XCTAssertEqual(source.selection, .bundled)
    }

    func testTrustedValidRemoteCanReplaceBundledCatalog() throws {
        let remote = try package(
            revision: 3,
            catalog: makeCatalog(id: "remote")
        )
        let source = RemoteFallbackContentSource(
            bundled: StaticContentSource(
                catalog: makeCatalog(id: "bundled")
            ),
            fetcher: MemoryRemoteContentFetcher(
                package: remote
            ),
            verifier: MemoryRemoteContentVerifier(
                trustedRevisions: [3]
            )
        )

        let catalog = try source.loadCatalog()

        XCTAssertEqual(catalog.discoveries.first?.id, "remote")
        XCTAssertEqual(source.selection, .remote(revision: 3))
    }

    func testInvalidTrustedRemoteStillFallsBackToBundled() throws {
        let invalid = ContentCatalog(
            schemaVersion: 999,
            lands: [],
            areas: [],
            discoveries: []
        )
        let remote = try package(
            revision: 4,
            catalog: invalid
        )
        let source = RemoteFallbackContentSource(
            bundled: StaticContentSource(
                catalog: makeCatalog(id: "bundled")
            ),
            fetcher: MemoryRemoteContentFetcher(
                package: remote
            ),
            verifier: MemoryRemoteContentVerifier(
                trustedRevisions: [4]
            )
        )

        let catalog = try source.loadCatalog()

        XCTAssertEqual(catalog.discoveries.first?.id, "bundled")
        XCTAssertEqual(source.selection, .bundled)
    }

    func testOlderThanMinimumRevisionFallsBack() throws {
        let remote = try package(
            revision: 1,
            catalog: makeCatalog(id: "remote")
        )
        let source = RemoteFallbackContentSource(
            bundled: StaticContentSource(
                catalog: makeCatalog(id: "bundled")
            ),
            fetcher: MemoryRemoteContentFetcher(
                package: remote
            ),
            verifier: MemoryRemoteContentVerifier(
                trustedRevisions: [1]
            ),
            minimumRevision: 2
        )

        XCTAssertEqual(
            try source.loadCatalog().discoveries.first?.id,
            "bundled"
        )
    }

    private func package(
        revision: Int,
        catalog: ContentCatalog
    ) throws -> RemoteContentPackage {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return RemoteContentPackage(
            revision: revision,
            catalogData: try encoder.encode(catalog),
            signature: Data([0x01])
        )
    }

    private func makeCatalog(id: String) -> ContentCatalog {
        let land = Land(
            id: "land",
            parkID: "disneyland",
            name: "Land",
            sortOrder: 1
        )
        return ContentCatalog(
            schemaVersion: ContentCatalog.currentSchemaVersion,
            lands: [land],
            areas: [],
            discoveries: [
                Discovery(
                    id: id,
                    title: id,
                    parkID: "disneyland",
                    landID: land.id,
                    areaID: nil,
                    category: .imagineeringDetail,
                    difficulty: .easy,
                    location: nil,
                    hints: [
                        Hint(id: "\(id)-h1", order: 1, text: "Look."),
                        Hint(id: "\(id)-h2", order: 2, text: "Look closer."),
                        Hint(
                            id: "\(id)-h3",
                            order: 3,
                            text: "Detailed clue.",
                            kind: .detailed
                        )
                    ],
                    revealDescription: "Reveal.",
                    revealImageName: nil,
                    verificationStatus: .verified,
                    lastVerifiedAt: Date(timeIntervalSince1970: 1_700_000_000),
                    isIndoor: false,
                    tags: []
                )
            ]
        )
    }
}

private struct StaticContentSource: ContentCatalogSource {
    let catalog: ContentCatalog

    func loadCatalog() throws -> ContentCatalog {
        catalog
    }
}
