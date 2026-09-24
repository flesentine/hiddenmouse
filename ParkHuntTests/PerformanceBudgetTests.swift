import Foundation
import XCTest
@testable import ParkHunt

final class PerformanceBudgetTests: XCTestCase {
    private static let scaledDiscoveryCount = 1_000

    func testScaledCatalogDecodeBudget() throws {
        let fixture = makeFixture(
            discoveryCount: Self.scaledDiscoveryCount
        )
        let data = try JSONEncoder().encode(fixture.catalog)

        let start = CFAbsoluteTimeGetCurrent()
        var decodedCount = 0

        for _ in 0 ..< 3 {
            let decoded = try ContentCatalogCodec.decode(data)
            decodedCount += decoded.discoveries.count
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertEqual(
            decodedCount,
            Self.scaledDiscoveryCount * 3
        )
        XCTAssertLessThan(
            elapsed,
            3.0,
            "Decoding a 1,000-discovery catalog three times exceeded the 3 s CI budget (\(elapsed) s)."
        )
    }

    func testScaledSnapshotLookupBudget() {
        let fixture = makeFixture(
            discoveryCount: Self.scaledDiscoveryCount
        )
        let snapshot = ContentSnapshot(catalog: fixture.catalog)

        let start = CFAbsoluteTimeGetCurrent()
        var checksum = 0

        for iteration in 0 ..< 20_000 {
            let discoveryIndex = iteration % Self.scaledDiscoveryCount
            let landIndex = discoveryIndex % fixture.lands.count
            let areaIndex = discoveryIndex % fixture.areas.count

            if snapshot.discovery(id: "discovery-\(discoveryIndex)") != nil {
                checksum += 1
            }

            checksum += snapshot
                .discoveries(inLand: "land-\(landIndex)")
                .count
            checksum += snapshot
                .discoveries(inArea: "area-\(areaIndex)")
                .count
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertGreaterThan(checksum, 0)
        XCTAssertLessThan(
            elapsed,
            2.0,
            "Indexed snapshot reads exceeded the 2 s CI budget (\(elapsed) s)."
        )
    }

    func testScaledCoreHuntLoopBudget() {
        let fixture = makeFixture(
            discoveryCount: Self.scaledDiscoveryCount
        )
        let snapshot = ContentSnapshot(catalog: fixture.catalog)
        let progress = fixture.progress
        let context = NearbyDiscoveryContext(
            parkID: "park",
            landID: "land-0",
            areaID: "area-0",
            locationFix: LocationFix(
                latitude: 33.8119,
                longitude: -117.9190,
                horizontalAccuracyMeters: 20,
                timestamp: Date()
            )
        )

        let start = CFAbsoluteTimeGetCurrent()
        var checksum = 0

        for _ in 0 ..< 5 {
            let nearby = NearbyDiscoveryEngine.results(
                snapshot: snapshot,
                context: context,
                filters: NearbyDiscoveryFilters(
                    scope: .park("park"),
                    found: .any
                ),
                progress: progress
            )
            let collection = CollectionSnapshot.make(
                snapshot: snapshot,
                progress: progress
            )
            let summary = ProgressSummary.make(
                snapshot: snapshot,
                progress: progress
            )

            checksum += nearby.count
            checksum += collection.items.count
            checksum += summary.overall.total
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertEqual(
            checksum,
            Self.scaledDiscoveryCount * 15
        )
        XCTAssertLessThan(
            elapsed,
            8.0,
            "Five full 1,000-discovery Nearby/Collection/Progress passes exceeded the 8 s CI budget (\(elapsed) s)."
        )
    }

    func testBundledColdLoadClockMetric() {
        measure(metrics: [XCTClockMetric()]) {
            let loader = ContentLoader()
            _ = try? loader.load()
        }
    }

    private func makeFixture(
        discoveryCount: Int
    ) -> (
        catalog: ContentCatalog,
        lands: [Land],
        areas: [AttractionArea],
        progress: UserProgress
    ) {
        let landCount = 20
        let areasPerLand = 2

        let lands = (0 ..< landCount).map { index in
            Land(
                id: "land-\(index)",
                parkID: "park",
                name: "Land \(index)",
                sortOrder: index
            )
        }

        let areas = (0 ..< landCount * areasPerLand).map { index in
            AttractionArea(
                id: "area-\(index)",
                landID: "land-\(index / areasPerLand)",
                name: "Area \(index)",
                kind: .area,
                sortOrder: index % areasPerLand
            )
        }

        let discoveries = (0 ..< discoveryCount).map { index in
            let landIndex = index % landCount
            let areaIndex = landIndex * areasPerLand
                + (index / landCount) % areasPerLand

            return Discovery(
                id: "discovery-\(index)",
                title: String(
                    format: "Discovery %04d",
                    index
                ),
                parkID: "park",
                landID: "land-\(landIndex)",
                areaID: "area-\(areaIndex)",
                category: DiscoveryCategory.allCases[
                    index % DiscoveryCategory.allCases.count
                ],
                difficulty: Difficulty.allCases[
                    index % Difficulty.allCases.count
                ],
                location: DiscoveryLocation(
                    latitude: 33.8119 + Double(index % 100) * 0.00001,
                    longitude: -117.9190,
                    radiusMeters: 100
                ),
                hints: [
                    Hint(
                        id: "discovery-\(index)-h1",
                        order: 1,
                        text: "Look nearby."
                    )
                ],
                revealDescription: "Synthetic performance fixture.",
                revealImageName: nil,
                verificationStatus: .verified,
                lastVerifiedAt: nil,
                isIndoor: false,
                tags: ["performance"]
            )
        }

        var progressByDiscovery: [String: DiscoveryProgress] = [:]
        progressByDiscovery.reserveCapacity(discoveryCount)

        for index in 0 ..< discoveryCount {
            let id = "discovery-\(index)"

            switch index % 4 {
            case 0:
                progressByDiscovery[id] = DiscoveryProgress(
                    discoveryID: id,
                    highestHintOrderViewed: 1,
                    foundAt: Date(timeIntervalSince1970: Double(index + 1)),
                    lastViewedAt: Date(timeIntervalSince1970: Double(index + 1))
                )
            case 1:
                progressByDiscovery[id] = DiscoveryProgress(
                    discoveryID: id,
                    highestHintOrderViewed: 1,
                    lastViewedAt: Date(timeIntervalSince1970: Double(index + 1))
                )
            default:
                break
            }
        }

        return (
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: lands,
                areas: areas,
                discoveries: discoveries
            ),
            lands: lands,
            areas: areas,
            progress: UserProgress(
                discoveries: progressByDiscovery
            )
        )
    }
}
