import Foundation

struct FamilyMember: Equatable, Identifiable, Sendable {
    let id: String
    let displayName: String
    let isCurrentUser: Bool
}

struct FamilyGroup: Equatable, Sendable {
    let id: String
    let name: String
    let members: [FamilyMember]
}

struct FamilySharedProgress: Equatable, Sendable {
    let foundDiscoveryIDs: Set<String>

    init(foundDiscoveryIDs: Set<String> = []) {
        self.foundDiscoveryIDs = foundDiscoveryIDs
    }
}

enum FamilySharingAvailability: Equatable, Sendable {
    case unavailable
    case notMember
    case ready(FamilyGroup)
}

enum FamilySharingResult: Equatable, Sendable {
    case unavailable
    case notMember
    case published
    case refreshed(FamilySharedProgress)
}

protocol FamilySharingProviding: AnyObject {
    func availability() -> FamilySharingAvailability
    func sharedProgress() throws -> FamilySharedProgress?
    func publishFoundProgress(_ progress: FamilySharedProgress) throws
}

final class NoopFamilySharingProvider: FamilySharingProviding {
    func availability() -> FamilySharingAvailability {
        .unavailable
    }

    func sharedProgress() throws -> FamilySharedProgress? {
        nil
    }

    func publishFoundProgress(
        _ progress: FamilySharedProgress
    ) throws {}
}

final class MemoryFamilySharingProvider: FamilySharingProviding {
    var group: FamilyGroup?
    var isAvailable: Bool
    private(set) var storedProgress: FamilySharedProgress?

    init(
        group: FamilyGroup? = nil,
        isAvailable: Bool = true,
        sharedProgress: FamilySharedProgress? = nil
    ) {
        self.group = group
        self.isAvailable = isAvailable
        self.storedProgress = sharedProgress
    }

    func availability() -> FamilySharingAvailability {
        guard isAvailable else {
            return .unavailable
        }

        guard let group else {
            return .notMember
        }

        return .ready(group)
    }

    func sharedProgress() throws -> FamilySharedProgress? {
        storedProgress
    }

    func publishFoundProgress(
        _ progress: FamilySharedProgress
    ) throws {
        let existing = storedProgress?.foundDiscoveryIDs ?? []
        storedProgress = FamilySharedProgress(
            foundDiscoveryIDs:
                existing.union(progress.foundDiscoveryIDs)
        )
    }
}

enum FamilyProgressProjection {
    static func sharedProgress(
        from personalProgress: UserProgress
    ) -> FamilySharedProgress {
        FamilySharedProgress(
            foundDiscoveryIDs: personalProgress.foundDiscoveryIDs
        )
    }
}

protocol FamilySharingServicing: AnyObject {
    func availability() -> FamilySharingAvailability
    func loadSharedProgress() -> FamilySharingResult
    func publishFoundProgress() -> FamilySharingResult
}

final class FamilySharingService: FamilySharingServicing {
    private let personalProgressStore: any UserProgressStoring
    private let provider: any FamilySharingProviding

    init(
        personalProgressStore: any UserProgressStoring,
        provider: any FamilySharingProviding
    ) {
        self.personalProgressStore = personalProgressStore
        self.provider = provider
    }

    func availability() -> FamilySharingAvailability {
        provider.availability()
    }

    func loadSharedProgress() -> FamilySharingResult {
        switch provider.availability() {
        case .unavailable:
            return .unavailable
        case .notMember:
            return .notMember
        case .ready:
            do {
                return .refreshed(
                    try provider.sharedProgress()
                        ?? FamilySharedProgress()
                )
            } catch {
                return .unavailable
            }
        }
    }

    func publishFoundProgress() -> FamilySharingResult {
        switch provider.availability() {
        case .unavailable:
            return .unavailable
        case .notMember:
            return .notMember
        case .ready:
            let personal = personalProgressStore.load()
            let projection = FamilyProgressProjection.sharedProgress(
                from: personal
            )

            do {
                try provider.publishFoundProgress(projection)
                return .published
            } catch {
                return .unavailable
            }
        }
    }
}
