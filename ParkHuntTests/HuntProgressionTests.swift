import XCTest
@testable import ParkHunt

final class HuntProgressionTests: XCTestCase {
    func testFreshHuntShowsOnlyFirstClue() {
        let discovery = makeDiscovery()

        let state = HuntProgressionState.make(
            discovery: discovery,
            progress: DiscoveryProgress(discoveryID: discovery.id)
        )

        XCTAssertEqual(state.visibleHints.map(\.id), ["h1"])
        XCTAssertEqual(state.nextAction, .revealHint(discovery.sortedHints[1]))
        XCTAssertFalse(state.isRevealVisible)
    }

    func testSecondClueAppearsAfterProgressAdvances() {
        let discovery = makeDiscovery()

        let state = HuntProgressionState.make(
            discovery: discovery,
            progress: DiscoveryProgress(
                discoveryID: discovery.id,
                highestHintOrderViewed: 2
            )
        )

        XCTAssertEqual(state.visibleHints.map(\.id), ["h1", "h2"])
        XCTAssertEqual(
            state.nextAction,
            .revealHint(discovery.sortedHints[2])
        )
        XCTAssertEqual(state.nextAction?.buttonTitle, "Give Me More Help")
    }

    func testDetailedHintLeadsToShowMe() {
        let discovery = makeDiscovery()

        let state = HuntProgressionState.make(
            discovery: discovery,
            progress: DiscoveryProgress(
                discoveryID: discovery.id,
                highestHintOrderViewed: 3
            )
        )

        XCTAssertEqual(state.visibleHints.map(\.id), ["h1", "h2", "h3"])
        XCTAssertEqual(state.nextAction, .revealLocation)
        XCTAssertEqual(state.nextAction?.buttonTitle, "Show Me")
    }

    func testRevealCompletesProgression() {
        let discovery = makeDiscovery()

        let state = HuntProgressionState.make(
            discovery: discovery,
            progress: DiscoveryProgress(
                discoveryID: discovery.id,
                highestHintOrderViewed: 3,
                didRevealLocation: true
            )
        )

        XCTAssertTrue(state.isRevealVisible)
        XCTAssertNil(state.nextAction)
    }

    func testRevealRestoresAllHintsEvenWithOlderSavedHintOrder() {
        let discovery = makeDiscovery()

        let state = HuntProgressionState.make(
            discovery: discovery,
            progress: DiscoveryProgress(
                discoveryID: discovery.id,
                highestHintOrderViewed: 1,
                didRevealLocation: true
            )
        )

        XCTAssertEqual(state.visibleHints.map(\.id), ["h1", "h2", "h3"])
        XCTAssertTrue(state.isRevealVisible)
        XCTAssertNil(state.nextAction)
    }

    func testHigherSavedOrderRestoresAllEarlierHints() {
        let discovery = makeDiscovery()

        let state = HuntProgressionState.make(
            discovery: discovery,
            progress: DiscoveryProgress(
                discoveryID: discovery.id,
                highestHintOrderViewed: 3
            )
        )

        XCTAssertEqual(state.visibleHints.map(\.order), [1, 2, 3])
    }

    func testNoHintsCanStillReachReveal() {
        let discovery = makeDiscovery(hints: [])

        let state = HuntProgressionState.make(
            discovery: discovery,
            progress: DiscoveryProgress(discoveryID: discovery.id)
        )

        XCTAssertTrue(state.visibleHints.isEmpty)
        XCTAssertEqual(state.nextAction, .revealLocation)
    }

    func testDetailedHintKindDecodesFromJSON() throws {
        let data = Data(
            #"{"id":"detail","order":3,"text":"More help","kind":"detailed"}"#
                .utf8
        )

        let hint = try JSONDecoder().decode(Hint.self, from: data)

        XCTAssertEqual(hint.resolvedKind, .detailed)
    }

    func testMissingHintKindDefaultsToClue() throws {
        let data = Data(
            #"{"id":"clue","order":1,"text":"Look up"}"#
                .utf8
        )

        let hint = try JSONDecoder().decode(Hint.self, from: data)

        XCTAssertEqual(hint.resolvedKind, .clue)
    }

    private func makeDiscovery(
        hints: [Hint]? = nil
    ) -> Discovery {
        Discovery(
            id: "secret",
            title: "Secret",
            parkID: "park",
            landID: "land",
            areaID: nil,
            category: .secretFeature,
            difficulty: .medium,
            location: nil,
            hints: hints ?? [
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
