import XCTest
@testable import ParkHunt

final class CloudSyncTests: XCTestCase {
    func testMergePreservesMostAdvancedProgress() {
        let early = Date(timeIntervalSince1970: 100)
        let late = Date(timeIntervalSince1970: 200)

        let local = UserProgress(
            discoveries: [
                "hunt": DiscoveryProgress(
                    discoveryID: "hunt",
                    highestHintOrderViewed: 1,
                    didRevealLocation: false,
                    foundAt: late,
                    lastViewedAt: late
                )
            ],
            lastUpdatedAt: late
        )
        let remote = UserProgress(
            discoveries: [
                "hunt": DiscoveryProgress(
                    discoveryID: "hunt",
                    highestHintOrderViewed: 3,
                    didRevealLocation: true,
                    foundAt: early,
                    lastViewedAt: early
                )
            ],
            lastUpdatedAt: early
        )

        let merged = UserProgressMerger.merge(
            local: local,
            remote: remote
        )
        let progress = merged.progress(for: "hunt")

        XCTAssertEqual(progress.highestHintOrderViewed, 3)
        XCTAssertTrue(progress.didRevealLocation)
        XCTAssertEqual(progress.foundAt, early)
        XCTAssertEqual(progress.lastViewedAt, late)
        XCTAssertEqual(merged.lastUpdatedAt, late)
    }

    func testSignedOutNeverTouchesLocalProgress() {
        let local = MemoryUserProgressStore()
        var progress = UserProgress()
        progress.recordFound(discoveryID: "hunt")
        local.save(progress)

        let service = CloudSyncService(
            localStore: local,
            accountProvider: MemoryCloudAccountProvider(
                account: nil
            ),
            cloudStore: MemoryCloudProgressStore()
        )

        XCTAssertEqual(service.sync(), .signedOut)
        XCTAssertEqual(local.load(), progress)
    }

    func testFirstSyncUploadsLocalProgress() {
        let account = CloudAccount(
            id: "account",
            displayName: "Tester"
        )
        let local = MemoryUserProgressStore()
        var progress = UserProgress()
        progress.recordFound(discoveryID: "hunt")
        local.save(progress)
        let cloud = MemoryCloudProgressStore()

        let service = CloudSyncService(
            localStore: local,
            accountProvider: MemoryCloudAccountProvider(
                account: account
            ),
            cloudStore: cloud
        )

        XCTAssertEqual(service.sync(), .uploaded)
        XCTAssertEqual(
            try? cloud.loadProgress(for: account),
            progress
        )
    }

    func testSyncMergesRemoteBackIntoLocalAndCloud() {
        let account = CloudAccount(
            id: "account",
            displayName: nil
        )
        let local = MemoryUserProgressStore()
        var localProgress = UserProgress()
        localProgress.recordHintViewed(
            discoveryID: "local",
            order: 2
        )
        local.save(localProgress)

        var remoteProgress = UserProgress()
        remoteProgress.recordFound(discoveryID: "remote")
        let cloud = MemoryCloudProgressStore(
            progressByAccountID: [
                account.id: remoteProgress
            ]
        )

        let service = CloudSyncService(
            localStore: local,
            accountProvider: MemoryCloudAccountProvider(
                account: account
            ),
            cloudStore: cloud
        )

        XCTAssertEqual(service.sync(), .merged)
        XCTAssertEqual(
            local.load().progress(for: "local")
                .highestHintOrderViewed,
            2
        )
        XCTAssertTrue(
            local.load().progress(for: "remote").isFound
        )
        XCTAssertEqual(
            try? cloud.loadProgress(for: account),
            local.load()
        )
    }

    func testUnavailableProviderDoesNotBlockLocalPlay() {
        let local = MemoryUserProgressStore()
        let service = CloudSyncService(
            localStore: local,
            accountProvider: MemoryCloudAccountProvider(
                account: nil,
                isAvailable: false
            ),
            cloudStore: MemoryCloudProgressStore()
        )

        XCTAssertEqual(service.availability(), .unavailable)
        XCTAssertEqual(service.sync(), .unavailable)

        var progress = local.load()
        progress.recordFound(discoveryID: "offline")
        local.save(progress)

        XCTAssertTrue(
            local.load().progress(for: "offline").isFound
        )
    }
}
