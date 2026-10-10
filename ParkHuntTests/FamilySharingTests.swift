import XCTest
@testable import ParkHunt

final class FamilySharingTests: XCTestCase {
    func testProjectionSharesOnlyFoundDiscoveryIDs() {
        var personal = UserProgress()
        personal.recordHintViewed(
            discoveryID: "started",
            order: 3
        )
        personal.recordRevealViewed(
            discoveryID: "revealed"
        )
        personal.recordFound(
            discoveryID: "found"
        )

        let shared = FamilyProgressProjection.sharedProgress(
            from: personal
        )

        XCTAssertEqual(shared.foundDiscoveryIDs, ["found"])
    }

    func testPublishingFamilyProgressDoesNotModifyPersonalProgress() {
        let local = MemoryUserProgressStore()
        var personal = UserProgress()
        personal.recordHintViewed(
            discoveryID: "private-hint",
            order: 2
        )
        personal.recordFound(discoveryID: "found")
        local.save(personal)

        let provider = MemoryFamilySharingProvider(
            group: makeGroup()
        )
        let service = FamilySharingService(
            personalProgressStore: local,
            provider: provider
        )

        XCTAssertEqual(
            service.publishFoundProgress(),
            .published
        )
        XCTAssertEqual(local.load(), personal)
        XCTAssertEqual(
            provider.storedProgress?.foundDiscoveryIDs,
            ["found"]
        )
    }

    func testProviderUnionsFindsAcrossFamilyPublishes() throws {
        let provider = MemoryFamilySharingProvider(
            group: makeGroup(),
            sharedProgress: FamilySharedProgress(
                foundDiscoveryIDs: ["other-find"]
            )
        )
        let local = MemoryUserProgressStore()
        var personal = UserProgress()
        personal.recordFound(discoveryID: "my-find")
        local.save(personal)

        let service = FamilySharingService(
            personalProgressStore: local,
            provider: provider
        )

        XCTAssertEqual(
            service.publishFoundProgress(),
            .published
        )
        XCTAssertEqual(
            try provider.sharedProgress()?.foundDiscoveryIDs,
            ["other-find", "my-find"]
        )
    }

    func testNotMemberCannotPublishOrLoad() {
        let service = FamilySharingService(
            personalProgressStore: MemoryUserProgressStore(),
            provider: MemoryFamilySharingProvider(
                group: nil
            )
        )

        XCTAssertEqual(service.availability(), .notMember)
        XCTAssertEqual(
            service.publishFoundProgress(),
            .notMember
        )
        XCTAssertEqual(
            service.loadSharedProgress(),
            .notMember
        )
    }

    func testUnavailableFamilyProviderDoesNotAffectLocalPlay() {
        let local = MemoryUserProgressStore()
        let service = FamilySharingService(
            personalProgressStore: local,
            provider: MemoryFamilySharingProvider(
                group: nil,
                isAvailable: false
            )
        )

        XCTAssertEqual(service.availability(), .unavailable)

        var progress = local.load()
        progress.recordFound(discoveryID: "offline")
        local.save(progress)

        XCTAssertTrue(
            local.load().progress(for: "offline").isFound
        )
    }

    private func makeGroup() -> FamilyGroup {
        FamilyGroup(
            id: "family",
            name: "Park Crew",
            members: [
                FamilyMember(
                    id: "me",
                    displayName: "Me",
                    isCurrentUser: true
                )
            ]
        )
    }
}
