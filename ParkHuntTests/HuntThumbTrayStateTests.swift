import XCTest
@testable import ParkHunt

final class HuntThumbTrayStateTests: XCTestCase {
    func testNormalHuntPutsNextHelpInMainThumbSlot() {
        let nextHint = Hint(
            id: "h2",
            order: 2,
            text: "Look higher."
        )
        let options = HuntAssistOptions(
            primaryAction: .revealHint(nextHint),
            secondaryAction: nil,
            preference: .normal
        )

        let state = HuntThumbTrayState.make(
            isFound: false,
            assistOptions: options,
            recommendation: nil
        )

        XCTAssertEqual(
            state.mode,
            .active(
                mainAssist: .revealHint(nextHint),
                alternateAssist: nil
            )
        )
    }

    func testExplorerPromotesSubtleHelpIntoReachableThumbSlot() {
        let nextHint = Hint(
            id: "h2",
            order: 2,
            text: "Look higher."
        )
        let options = HuntAssistOptions(
            primaryAction: nil,
            secondaryAction: .revealHint(nextHint),
            preference: .explorer
        )

        let state = HuntThumbTrayState.make(
            isFound: false,
            assistOptions: options,
            recommendation: nil
        )

        XCTAssertEqual(
            state.mode,
            .active(
                mainAssist: .revealHint(nextHint),
                alternateAssist: nil
            )
        )
    }

    func testHelpMeKeepsStandardClueAsAlternateAction() {
        let detailed = Hint(
            id: "detail",
            order: 3,
            text: "Look above the arch.",
            kind: .detailed
        )
        let standard = Hint(
            id: "h2",
            order: 2,
            text: "Look higher."
        )
        let options = HuntAssistOptions(
            primaryAction: .revealHint(detailed),
            secondaryAction: .revealHint(standard),
            preference: .helpMe
        )

        let state = HuntThumbTrayState.make(
            isFound: false,
            assistOptions: options,
            recommendation: nil
        )

        XCTAssertEqual(
            state.mode,
            .active(
                mainAssist: .revealHint(detailed),
                alternateAssist: .revealHint(standard)
            )
        )
    }

    func testCompletedHuntReplacesHelpWithFindAnother() {
        let recommendation = makeResult(
            id: "next",
            title: "Next Secret"
        )
        let options = HuntAssistOptions(
            primaryAction: .revealLocation,
            secondaryAction: nil,
            preference: .showMe
        )

        let state = HuntThumbTrayState.make(
            isFound: true,
            assistOptions: options,
            recommendation: recommendation
        )

        XCTAssertEqual(
            state.mode,
            .completed(
                nextDiscoveryID: "next",
                nextDiscoveryTitle: "Next Secret"
            )
        )
    }

    func testCompletedHuntWithNoRecommendationHasNoNextAction() {
        let options = HuntAssistOptions(
            primaryAction: nil,
            secondaryAction: nil,
            preference: .normal
        )

        let state = HuntThumbTrayState.make(
            isFound: true,
            assistOptions: options,
            recommendation: nil
        )

        XCTAssertEqual(
            state.mode,
            .completed(
                nextDiscoveryID: nil,
                nextDiscoveryTitle: nil
            )
        )
    }

    private func makeResult(
        id: String,
        title: String
    ) -> NearbyDiscoveryResult {
        NearbyDiscoveryResult(
            discovery: Discovery(
                id: id,
                title: title,
                parkID: "park",
                landID: "land",
                areaID: nil,
                category: .secretFeature,
                difficulty: .easy,
                location: nil,
                hints: [
                    Hint(
                        id: "\(id)-h1",
                        order: 1,
                        text: "Look."
                    )
                ],
                revealDescription: "Reveal.",
                revealImageName: nil,
                verificationStatus: .verified,
                lastVerifiedAt: nil,
                isIndoor: false,
                tags: []
            ),
            distanceMeters: 100,
            isFound: false,
            matchesPark: true,
            matchesLand: true,
            matchesArea: false
        )
    }
}
