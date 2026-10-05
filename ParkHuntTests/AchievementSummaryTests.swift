import XCTest
@testable import ParkHunt

final class AchievementSummaryTests: XCTestCase {
    func testFirstFindUnlocksAtOne() {
        let snapshot = makeSnapshot(count: 5)
        var progress = UserProgress()
        progress.recordFound(discoveryID: "hunt-0")

        let summary = AchievementSummary.make(
            snapshot: snapshot,
            progress: progress
        )

        XCTAssertEqual(
            summary.achievements.first { $0.kind == .firstFind }?.isUnlocked,
            true
        )
    }

    func testCountMilestonesUseCurrentFoundCount() {
        let snapshot = makeSnapshot(count: 12)
        var progress = UserProgress()
        for index in 0..<10 {
            progress.recordFound(discoveryID: "hunt-\(index)")
        }

        let summary = AchievementSummary.make(
            snapshot: snapshot,
            progress: progress
        )

        XCTAssertEqual(
            summary.achievements.first { $0.kind == .tenFinds }?.isUnlocked,
            true
        )
        XCTAssertEqual(
            summary.achievements.first { $0.kind == .twentyFiveFinds }?.current,
            10
        )
    }

    func testLandCompleteRequiresEveryHuntInLand() {
        let snapshot = makeSnapshot(count: 3)
        var progress = UserProgress()
        progress.recordFound(discoveryID: "hunt-0")
        progress.recordFound(discoveryID: "hunt-1")

        var summary = AchievementSummary.make(
            snapshot: snapshot,
            progress: progress
        )
        XCTAssertEqual(
            summary.achievements.first { $0.kind == .landComplete }?.isUnlocked,
            false
        )

        progress.recordFound(discoveryID: "hunt-2")
        summary = AchievementSummary.make(
            snapshot: snapshot,
            progress: progress
        )
        XCTAssertEqual(
            summary.achievements.first { $0.kind == .landComplete }?.isUnlocked,
            true
        )
    }

    func testCategoryExplorerNeedsThreeFoundCategories() {
        let snapshot = makeSnapshot(count: 3, categories: [
            .hiddenMickey,
            .secretFeature,
            .historicalDetail
        ])
        var progress = UserProgress()
        progress.recordFound(discoveryID: "hunt-0")
        progress.recordFound(discoveryID: "hunt-1")
        progress.recordFound(discoveryID: "hunt-2")

        let summary = AchievementSummary.make(
            snapshot: snapshot,
            progress: progress
        )

        XCTAssertEqual(
            summary.achievements.first { $0.kind == .categoryExplorer }?.isUnlocked,
            true
        )
    }

    private func makeSnapshot(
        count: Int,
        categories: [DiscoveryCategory]? = nil
    ) -> ContentSnapshot {
        let discoveries = (0..<count).map { index in
            Discovery(
                id: "hunt-\(index)",
                title: "Hunt \(index)",
                parkID: "park",
                landID: "land",
                areaID: nil,
                category: categories?[index] ?? .imagineeringDetail,
                difficulty: .easy,
                location: nil,
                hints: [Hint(id: "hunt-\(index)-h1", order: 1, text: "Look.")],
                revealDescription: "Reveal.",
                revealImageName: nil,
                verificationStatus: .verified,
                lastVerifiedAt: nil,
                isIndoor: false,
                tags: []
            )
        }

        return ContentSnapshot(
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
                discoveries: discoveries
            )
        )
    }
}
