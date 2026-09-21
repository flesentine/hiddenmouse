import XCTest
@testable import ParkHunt

final class HuntAssistPolicyTests: XCTestCase {
    func testExplorerKeepsNextHelpSecondary() {
        let discovery = makeDiscovery()
        let progression = freshProgression(discovery)

        let options = HuntAssistOptions.make(
            discovery: discovery,
            progression: progression,
            preference: .explorer
        )

        XCTAssertNil(options.primaryAction)
        XCTAssertEqual(
            options.secondaryAction,
            progression.nextAction
        )
    }

    func testNormalUsesStandardNextAction() {
        let discovery = makeDiscovery()
        let progression = freshProgression(discovery)

        let options = HuntAssistOptions.make(
            discovery: discovery,
            progression: progression,
            preference: .normal
        )

        XCTAssertEqual(
            options.primaryAction,
            progression.nextAction
        )
        XCTAssertNil(options.secondaryAction)
    }

    func testHelpMeCanJumpToDetailedHint() {
        let discovery = makeDiscovery()
        let progression = freshProgression(discovery)

        let options = HuntAssistOptions.make(
            discovery: discovery,
            progression: progression,
            preference: .helpMe
        )

        XCTAssertEqual(
            options.primaryAction,
            .revealHint(discovery.sortedHints[2])
        )
        XCTAssertEqual(
            options.secondaryAction,
            progression.nextAction
        )
    }

    func testHelpMeFallsBackToStandardActionWhenNoDetailedHintRemains() {
        let discovery = makeDiscovery()
        let progression = HuntProgressionState.make(
            discovery: discovery,
            progress: DiscoveryProgress(
                discoveryID: discovery.id,
                highestHintOrderViewed: 3
            )
        )

        let options = HuntAssistOptions.make(
            discovery: discovery,
            progression: progression,
            preference: .helpMe
        )

        XCTAssertEqual(options.primaryAction, .revealLocation)
        XCTAssertNil(options.secondaryAction)
    }

    func testShowMeOffersRevealImmediatelyAndKeepsStandardHelpSecondary() {
        let discovery = makeDiscovery()
        let progression = freshProgression(discovery)

        let options = HuntAssistOptions.make(
            discovery: discovery,
            progression: progression,
            preference: .showMe
        )

        XCTAssertEqual(options.primaryAction, .revealLocation)
        XCTAssertEqual(
            options.secondaryAction,
            progression.nextAction
        )
    }

    func testRevealedHuntHasNoFurtherActionsInAnyMode() {
        let discovery = makeDiscovery()
        let progression = HuntProgressionState.make(
            discovery: discovery,
            progress: DiscoveryProgress(
                discoveryID: discovery.id,
                didRevealLocation: true
            )
        )

        for preference in SpoilerPreference.allCases {
            let options = HuntAssistOptions.make(
                discovery: discovery,
                progression: progression,
                preference: preference
            )

            XCTAssertNil(options.primaryAction)
            XCTAssertNil(options.secondaryAction)
        }
    }

    private func freshProgression(
        _ discovery: Discovery
    ) -> HuntProgressionState {
        HuntProgressionState.make(
            discovery: discovery,
            progress: DiscoveryProgress(discoveryID: discovery.id)
        )
    }

    private func makeDiscovery() -> Discovery {
        Discovery(
            id: "secret",
            title: "Secret",
            parkID: "park",
            landID: "land",
            areaID: nil,
            category: .secretFeature,
            difficulty: .medium,
            location: nil,
            hints: [
                Hint(id: "h1", order: 1, text: "First"),
                Hint(id: "h2", order: 2, text: "Second"),
                Hint(
                    id: "h3",
                    order: 3,
                    text: "Detailed",
                    kind: .detailed
                )
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
