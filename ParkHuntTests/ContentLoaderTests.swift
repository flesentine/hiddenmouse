import XCTest
@testable import ParkHunt

final class ContentLoaderTests: XCTestCase {
    func testLoadCachesFirstSnapshot() throws {
        let source = CountingContentSource(catalogs: [
            makeCatalog(discoveryID: "first"),
            makeCatalog(discoveryID: "second")
        ])
        let loader = ContentLoader(source: source)

        let first = try loader.load()
        let second = try loader.load()

        XCTAssertEqual(source.loadCount, 1)
        XCTAssertEqual(first.catalog, second.catalog)
        XCTAssertEqual(first.discoveries.first?.id, "first")
    }

    func testReloadRefreshesSnapshotFromSource() throws {
        let source = CountingContentSource(catalogs: [
            makeCatalog(discoveryID: "first"),
            makeCatalog(discoveryID: "second")
        ])
        let loader = ContentLoader(source: source)

        XCTAssertEqual(try loader.load().discoveries.first?.id, "first")
        XCTAssertEqual(try loader.reload().discoveries.first?.id, "second")
        XCTAssertEqual(source.loadCount, 2)
    }

    func testResetForcesNextLoad() throws {
        let source = CountingContentSource(catalogs: [
            makeCatalog(discoveryID: "first"),
            makeCatalog(discoveryID: "second")
        ])
        let loader = ContentLoader(source: source)

        _ = try loader.load()
        loader.reset()
        let reloaded = try loader.load()

        XCTAssertEqual(source.loadCount, 2)
        XCTAssertEqual(reloaded.discoveries.first?.id, "second")
    }

    func testSnapshotIndexesLandAreaAndDiscovery() {
        let catalog = makeCatalog(discoveryID: "secret")
        let snapshot = ContentSnapshot(catalog: catalog)

        XCTAssertEqual(snapshot.land(id: "land-a")?.name, "Land A")
        XCTAssertEqual(snapshot.area(id: "area-a")?.name, "Area A")
        XCTAssertEqual(snapshot.discovery(id: "secret")?.title, "Secret secret")
        XCTAssertEqual(snapshot.areas(inLand: "land-a").map(\.id), ["area-a"])
        XCTAssertEqual(snapshot.discoveries(inLand: "land-a").map(\.id), ["secret"])
        XCTAssertEqual(snapshot.discoveries(inArea: "area-a").map(\.id), ["secret"])
        XCTAssertEqual(snapshot.discoveries(category: .hiddenMickey).map(\.id), ["secret"])
    }

    func testUnavailableDiscoveriesAreHiddenByDefault() {
        let available = makeDiscovery(
            id: "available",
            status: .verified
        )
        let removed = makeDiscovery(
            id: "removed",
            status: .removed
        )
        let temporary = makeDiscovery(
            id: "temporary",
            status: .temporarilyUnavailable
        )
        let catalog = makeCatalog(
            discoveries: [available, removed, temporary]
        )
        let snapshot = ContentSnapshot(catalog: catalog)

        XCTAssertEqual(snapshot.discoveries.map(\.id), ["available"])
        XCTAssertNil(snapshot.discovery(id: "removed"))
        XCTAssertNil(snapshot.discovery(id: "temporary"))
        XCTAssertEqual(
            snapshot.discoveries(inLand: "land-a", includeUnavailable: true).map(\.id),
            ["available", "removed", "temporary"]
        )
        XCTAssertEqual(
            snapshot.discovery(id: "removed", includeUnavailable: true)?.id,
            "removed"
        )
    }

    func testLandAndAreaSortingIsStable() {
        let catalog = ContentCatalog(
            schemaVersion: ContentCatalog.currentSchemaVersion,
            lands: [
                Land(id: "b", parkID: "park", name: "Beta", sortOrder: 2),
                Land(id: "a", parkID: "park", name: "Alpha", sortOrder: 1)
            ],
            areas: [
                AttractionArea(id: "b2", landID: "a", name: "Beta", kind: .area, sortOrder: 2),
                AttractionArea(id: "a1", landID: "a", name: "Alpha", kind: .area, sortOrder: 1)
            ],
            discoveries: []
        )

        let snapshot = ContentSnapshot(catalog: catalog)

        XCTAssertEqual(snapshot.lands.map(\.id), ["a", "b"])
        XCTAssertEqual(snapshot.areas.map(\.id), ["a1", "b2"])
    }

    func testRealBundledCatalogLoadsThroughApplicationLoader() throws {
        let loader = ContentLoader()
        let snapshot = try loader.load()

        XCTAssertEqual(snapshot.catalog.schemaVersion, ContentCatalog.currentSchemaVersion)
        XCTAssertFalse(snapshot.lands.isEmpty)
        XCTAssertFalse(snapshot.discoveries.isEmpty)
    }

    func testBundledCatalogContainsNewOrleansSquareFieldTestContent() throws {
        let snapshot = try ContentLoader().load()
        let discoveries = snapshot.discoveries(inLand: "new-orleans-square")
        let ids = Set(discoveries.map(\.id))

        XCTAssertGreaterThanOrEqual(discoveries.count, 18)
        XCTAssertTrue(ids.contains("royal-street-louisiana-flag"))
        XCTAssertTrue(ids.contains("riverfront-1764-mark"))
        XCTAssertTrue(ids.contains("mansion-greenhouse-strange-plants"))
        XCTAssertFalse(ids.contains("prototype-secret-001"))
        XCTAssertTrue(discoveries.allSatisfy { $0.sortedHints.count >= 3 })
    }

    private func makeCatalog(discoveryID: String) -> ContentCatalog {
        makeCatalog(discoveries: [makeDiscovery(id: discoveryID)])
    }

    private func makeCatalog(
        discoveries: [Discovery]
    ) -> ContentCatalog {
        ContentCatalog(
            schemaVersion: ContentCatalog.currentSchemaVersion,
            lands: [
                Land(
                    id: "land-a",
                    parkID: "park",
                    name: "Land A",
                    sortOrder: 1
                )
            ],
            areas: [
                AttractionArea(
                    id: "area-a",
                    landID: "land-a",
                    name: "Area A",
                    kind: .area,
                    sortOrder: 1
                )
            ],
            discoveries: discoveries
        )
    }

    private func makeDiscovery(
        id: String,
        status: VerificationStatus = .verified
    ) -> Discovery {
        Discovery(
            id: id,
            title: "Secret \(id)",
            parkID: "park",
            landID: "land-a",
            areaID: "area-a",
            category: .hiddenMickey,
            difficulty: .easy,
            location: DiscoveryLocation(
                latitude: 33.81,
                longitude: -117.92,
                radiusMeters: 75
            ),
            hints: [
                Hint(
                    id: "\(id)-hint-1",
                    order: 1,
                    text: "Look nearby."
                )
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

private final class CountingContentSource: ContentCatalogSource {
    private var catalogs: [ContentCatalog]
    private(set) var loadCount = 0

    init(catalogs: [ContentCatalog]) {
        self.catalogs = catalogs
    }

    func loadCatalog() throws -> ContentCatalog {
        loadCount += 1

        if catalogs.count > 1 {
            return catalogs.removeFirst()
        }

        guard let catalog = catalogs.first else {
            throw TestContentSourceError.empty
        }

        return catalog
    }
}

private enum TestContentSourceError: Error {
    case empty
}
