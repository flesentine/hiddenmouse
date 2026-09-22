import XCTest
@testable import ParkHunt

final class ActiveHuntRestorationTests: XCTestCase {
    func testMemoryStoreRoundTripsSession() {
        let store = MemoryActiveHuntStore()
        let session = ActiveHuntSession(
            discoveryID: "secret",
            isRevealPresented: true
        )

        store.save(session)

        XCTAssertEqual(store.load(), session)

        store.clear()

        XCTAssertNil(store.load())
    }

    func testUserDefaultsStoreRoundTripsAndClears() {
        let suiteName = "ParkHuntTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsActiveHuntStore(
            defaults: defaults,
            storageKey: "active-hunt"
        )
        let session = ActiveHuntSession(
            discoveryID: "secret",
            isRevealPresented: true
        )

        store.save(session)
        XCTAssertEqual(store.load(), session)

        store.clear()
        XCTAssertNil(store.load())
    }

    func testRestorerPreservesRevealScreenState() {
        let snapshot = makeSnapshot()
        let session = ActiveHuntSession(
            discoveryID: "secret",
            isRevealPresented: true
        )

        XCTAssertEqual(
            ActiveHuntRestorer.restorableSession(
                storedSession: session,
                snapshot: snapshot,
                progress: UserProgress()
            ),
            session
        )
    }

    func testRestorerRejectsCompletedHunt() {
        let snapshot = makeSnapshot()
        var progress = UserProgress()
        progress.recordFound(
            discoveryID: "secret",
            at: Date(timeIntervalSince1970: 100)
        )

        XCTAssertNil(
            ActiveHuntRestorer.restorableSession(
                storedSession: ActiveHuntSession(
                    discoveryID: "secret"
                ),
                snapshot: snapshot,
                progress: progress
            )
        )
    }

    func testRestorerRejectsDiscoveryNoLongerInCatalog() {
        XCTAssertNil(
            ActiveHuntRestorer.restorableSession(
                storedSession: ActiveHuntSession(
                    discoveryID: "missing"
                ),
                snapshot: makeSnapshot(),
                progress: UserProgress()
            )
        )
    }

    func testSavedHintStageRestoresWithoutAdvancing() {
        let discovery = makeDiscovery()
        let progress = DiscoveryProgress(
            discoveryID: discovery.id,
            highestHintOrderViewed: 2,
            didRevealLocation: false,
            foundAt: nil,
            lastViewedAt: Date(timeIntervalSince1970: 100)
        )

        let state = HuntProgressionState.make(
            discovery: discovery,
            progress: progress
        )

        XCTAssertEqual(
            state.visibleHints.map(\.order),
            [1, 2]
        )
        XCTAssertEqual(
            state.nextAction,
            .revealHint(discovery.sortedHints[2])
        )
        XCTAssertFalse(state.isRevealVisible)
    }

    func testSavedRevealStateRestoresAllHintsAndReveal() {
        let discovery = makeDiscovery()
        let progress = DiscoveryProgress(
            discoveryID: discovery.id,
            highestHintOrderViewed: 1,
            didRevealLocation: true,
            foundAt: nil,
            lastViewedAt: Date(timeIntervalSince1970: 100)
        )

        let state = HuntProgressionState.make(
            discovery: discovery,
            progress: progress
        )

        XCTAssertEqual(
            state.visibleHints.map(\.order),
            [1, 2, 3]
        )
        XCTAssertTrue(state.isRevealVisible)
        XCTAssertNil(state.nextAction)
    }

    private func makeSnapshot() -> ContentSnapshot {
        ContentSnapshot(
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
                discoveries: [makeDiscovery()]
            )
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
            difficulty: .easy,
            location: nil,
            hints: [
                Hint(id: "h1", order: 1, text: "First."),
                Hint(id: "h2", order: 2, text: "Second."),
                Hint(
                    id: "h3",
                    order: 3,
                    text: "Detailed.",
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
