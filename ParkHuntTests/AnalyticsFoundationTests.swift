import XCTest
@testable import ParkHunt

final class AnalyticsFoundationTests: XCTestCase {
    func testAppOpenContainsNoDiscoveryContext() {
        let date = Date(timeIntervalSince1970: 100)
        let event = AnalyticsEventRecord.appOpen(at: date)

        XCTAssertEqual(event.name, .appOpen)
        XCTAssertEqual(event.timestamp, date)
        XCTAssertNil(event.discoveryID)
        XCTAssertNil(event.landID)
        XCTAssertNil(event.category)
        XCTAssertNil(event.difficulty)
        XCTAssertNil(event.hintOrder)
        XCTAssertNil(event.nextDiscoveryID)
    }

    func testClueAndDetailedHelpAreDistinctEvents() {
        let discovery = makeDiscovery()
        let clue = Hint(
            id: "h2",
            order: 2,
            text: "Secret clue text."
        )
        let detailed = Hint(
            id: "h3",
            order: 3,
            text: "Secret detailed text.",
            kind: .detailed
        )

        let clueEvent = AnalyticsEventRecord.assistAction(
            .revealHint(clue),
            discovery: discovery
        )
        let detailedEvent = AnalyticsEventRecord.assistAction(
            .revealHint(detailed),
            discovery: discovery
        )

        XCTAssertEqual(clueEvent.name, .clueRevealed)
        XCTAssertEqual(clueEvent.hintOrder, 2)
        XCTAssertEqual(clueEvent.hintKind, .clue)

        XCTAssertEqual(
            detailedEvent.name,
            .detailedHelpRevealed
        )
        XCTAssertEqual(detailedEvent.hintOrder, 3)
        XCTAssertEqual(detailedEvent.hintKind, .detailed)
    }

    func testRevealFoundAndFindAnotherUseTypedEvents() {
        let discovery = makeDiscovery()

        XCTAssertEqual(
            AnalyticsEventRecord.assistAction(
                .revealLocation,
                discovery: discovery
            ).name,
            .fullRevealOpened
        )

        XCTAssertEqual(
            AnalyticsEventRecord.discoveryFound(
                discovery: discovery
            ).name,
            .discoveryFound
        )

        let next = AnalyticsEventRecord.findAnotherTapped(
            currentDiscovery: discovery,
            nextDiscoveryID: "next"
        )
        XCTAssertEqual(next.name, .findAnotherTapped)
        XCTAssertEqual(next.discoveryID, discovery.id)
        XCTAssertEqual(next.nextDiscoveryID, "next")
    }

    func testRestorationCapturesRevealStateWithoutLocation() {
        let discovery = makeDiscovery()
        let event = AnalyticsEventRecord.activeHuntRestored(
            discovery: discovery,
            revealWasOpen: true
        )

        XCTAssertEqual(event.name, .activeHuntRestored)
        XCTAssertEqual(event.restoredRevealWasOpen, true)
        XCTAssertEqual(event.discoveryID, discovery.id)
    }

    func testEncodedEventDoesNotContainSensitiveContent() throws {
        let discovery = makeDiscovery()
        let secretHint = Hint(
            id: "h2",
            order: 2,
            text: "DO NOT STORE THIS CLUE"
        )
        let event = AnalyticsEventRecord.assistAction(
            .revealHint(secretHint),
            discovery: discovery
        )

        let data = try JSONEncoder().encode(event)
        let encoded = String(decoding: data, as: UTF8.self)

        XCTAssertFalse(encoded.contains("DO NOT STORE THIS CLUE"))
        XCTAssertFalse(encoded.contains("33.81234"))
        XCTAssertFalse(encoded.contains("-117.91987"))
        XCTAssertFalse(encoded.contains("revealImageName"))
        XCTAssertFalse(encoded.contains("thumbnailImageName"))
        XCTAssertFalse(encoded.contains("latitude"))
        XCTAssertFalse(encoded.contains("longitude"))
    }

    func testMemoryRecorderCapsOldestEvents() {
        let recorder = MemoryAnalyticsRecorder(
            maximumEventCount: 3
        )

        recorder.record(
            .appOpen(at: Date(timeIntervalSince1970: 1))
        )
        recorder.record(
            .appOpen(at: Date(timeIntervalSince1970: 2))
        )
        recorder.record(
            .appOpen(at: Date(timeIntervalSince1970: 3))
        )
        recorder.record(
            .appOpen(at: Date(timeIntervalSince1970: 4))
        )

        XCTAssertEqual(
            recorder.events().map(\.timestamp),
            [
                Date(timeIntervalSince1970: 2),
                Date(timeIntervalSince1970: 3),
                Date(timeIntervalSince1970: 4)
            ]
        )
    }

    func testUserDefaultsRecorderRoundTripsAndClears() {
        let suiteName = "ParkHuntTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let recorder = UserDefaultsAnalyticsRecorder(
            defaults: defaults,
            storageKey: "analytics",
            maximumEventCount: 10
        )
        let event = AnalyticsEventRecord.huntStarted(
            discovery: makeDiscovery(),
            at: Date(timeIntervalSince1970: 500)
        )

        recorder.record(event)

        XCTAssertEqual(recorder.events(), [event])

        recorder.clear()

        XCTAssertTrue(recorder.events().isEmpty)
    }

    private func makeDiscovery() -> Discovery {
        Discovery(
            id: "secret",
            title: "Secret",
            parkID: "park",
            landID: "land",
            areaID: "area",
            category: .easterEgg,
            difficulty: .medium,
            location: DiscoveryLocation(
                latitude: 33.81234,
                longitude: -117.91987,
                radiusMeters: 25
            ),
            hints: [
                Hint(
                    id: "h1",
                    order: 1,
                    text: "First clue."
                )
            ],
            revealDescription: "Secret reveal text.",
            revealImageName: "secret-reveal.jpg",
            thumbnailImageName: "secret-thumb.jpg",
            verificationStatus: .verified,
            lastVerifiedAt: nil,
            isIndoor: false,
            tags: ["private-tag"]
        )
    }
}
