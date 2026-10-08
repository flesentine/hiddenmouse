import Foundation

struct CloudAccount: Equatable, Sendable {
    let id: String
    let displayName: String?
}

enum CloudSyncAvailability: Equatable, Sendable {
    case signedOut
    case ready(CloudAccount)
    case unavailable
}

enum CloudSyncResult: Equatable, Sendable {
    case signedOut
    case unavailable
    case uploaded
    case merged
}

protocol CloudAccountProviding: AnyObject {
    func currentAccount() -> CloudAccount?
    var isAvailable: Bool { get }
}

protocol CloudProgressStoring: AnyObject {
    func loadProgress(for account: CloudAccount) throws -> UserProgress?
    func saveProgress(
        _ progress: UserProgress,
        for account: CloudAccount
    ) throws
}

final class NoopCloudAccountProvider: CloudAccountProviding {
    var isAvailable: Bool { false }

    func currentAccount() -> CloudAccount? {
        nil
    }
}

final class NoopCloudProgressStore: CloudProgressStoring {
    func loadProgress(for account: CloudAccount) throws -> UserProgress? {
        nil
    }

    func saveProgress(
        _ progress: UserProgress,
        for account: CloudAccount
    ) throws {}
}

final class MemoryCloudAccountProvider: CloudAccountProviding {
    var account: CloudAccount?
    var isAvailable: Bool

    init(
        account: CloudAccount? = nil,
        isAvailable: Bool = true
    ) {
        self.account = account
        self.isAvailable = isAvailable
    }

    func currentAccount() -> CloudAccount? {
        account
    }
}

final class MemoryCloudProgressStore: CloudProgressStoring {
    private(set) var progressByAccountID: [String: UserProgress]

    init(progressByAccountID: [String: UserProgress] = [:]) {
        self.progressByAccountID = progressByAccountID
    }

    func loadProgress(for account: CloudAccount) throws -> UserProgress? {
        progressByAccountID[account.id]
    }

    func saveProgress(
        _ progress: UserProgress,
        for account: CloudAccount
    ) throws {
        progressByAccountID[account.id] = progress
    }
}

enum UserProgressMerger {
    static func merge(
        local: UserProgress,
        remote: UserProgress
    ) -> UserProgress {
        let ids = Set(local.discoveries.keys)
            .union(remote.discoveries.keys)

        var discoveries: [String: DiscoveryProgress] = [:]

        for id in ids {
            let lhs = local.progress(for: id)
            let rhs = remote.progress(for: id)

            discoveries[id] = DiscoveryProgress(
                discoveryID: id,
                highestHintOrderViewed: maxOptional(
                    lhs.highestHintOrderViewed,
                    rhs.highestHintOrderViewed
                ),
                didRevealLocation:
                    lhs.didRevealLocation || rhs.didRevealLocation,
                foundAt: minDate(lhs.foundAt, rhs.foundAt),
                lastViewedAt: maxDate(lhs.lastViewedAt, rhs.lastViewedAt)
            )
        }

        return UserProgress(
            discoveries: discoveries,
            lastUpdatedAt: maxDate(
                local.lastUpdatedAt,
                remote.lastUpdatedAt
            )
        )
    }

    private static func maxOptional(
        _ lhs: Int?,
        _ rhs: Int?
    ) -> Int? {
        switch (lhs, rhs) {
        case let (.some(lhs), .some(rhs)):
            max(lhs, rhs)
        case let (.some(lhs), .none):
            lhs
        case let (.none, .some(rhs)):
            rhs
        case (.none, .none):
            nil
        }
    }

    private static func minDate(
        _ lhs: Date?,
        _ rhs: Date?
    ) -> Date? {
        switch (lhs, rhs) {
        case let (.some(lhs), .some(rhs)):
            min(lhs, rhs)
        case let (.some(lhs), .none):
            lhs
        case let (.none, .some(rhs)):
            rhs
        case (.none, .none):
            nil
        }
    }

    private static func maxDate(
        _ lhs: Date?,
        _ rhs: Date?
    ) -> Date? {
        switch (lhs, rhs) {
        case let (.some(lhs), .some(rhs)):
            max(lhs, rhs)
        case let (.some(lhs), .none):
            lhs
        case let (.none, .some(rhs)):
            rhs
        case (.none, .none):
            nil
        }
    }
}

protocol CloudSyncServicing: AnyObject {
    func availability() -> CloudSyncAvailability
    func sync() -> CloudSyncResult
}

final class CloudSyncService: CloudSyncServicing {
    private let localStore: any UserProgressStoring
    private let accountProvider: any CloudAccountProviding
    private let cloudStore: any CloudProgressStoring

    init(
        localStore: any UserProgressStoring,
        accountProvider: any CloudAccountProviding,
        cloudStore: any CloudProgressStoring
    ) {
        self.localStore = localStore
        self.accountProvider = accountProvider
        self.cloudStore = cloudStore
    }

    func availability() -> CloudSyncAvailability {
        guard accountProvider.isAvailable else {
            return .unavailable
        }

        guard let account = accountProvider.currentAccount() else {
            return .signedOut
        }

        return .ready(account)
    }

    func sync() -> CloudSyncResult {
        guard accountProvider.isAvailable else {
            return .unavailable
        }

        guard let account = accountProvider.currentAccount() else {
            return .signedOut
        }

        let local = localStore.load()

        do {
            guard let remote = try cloudStore.loadProgress(
                for: account
            ) else {
                try cloudStore.saveProgress(local, for: account)
                return .uploaded
            }

            let merged = UserProgressMerger.merge(
                local: local,
                remote: remote
            )
            localStore.save(merged)
            try cloudStore.saveProgress(merged, for: account)
            return .merged
        } catch {
            return .unavailable
        }
    }
}
