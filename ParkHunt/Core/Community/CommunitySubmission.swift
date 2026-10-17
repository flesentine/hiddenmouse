import Foundation

enum CommunitySubmissionStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case draft
    case submitted
    case underReview
    case approved
    case rejected

    var displayName: String {
        switch self {
        case .draft: "Draft"
        case .submitted: "Submitted"
        case .underReview: "Under Review"
        case .approved: "Approved for Editorial Review"
        case .rejected: "Not Accepted"
        }
    }
}

struct CommunitySubmission: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var parkID: String
    var landID: String
    var detailDescription: String
    var clueSuggestion: String
    var categorySuggestion: DiscoveryCategory?
    var status: CommunitySubmissionStatus
    let createdAt: Date
    var submittedAt: Date?
    var moderationNote: String?

    init(
        id: UUID = UUID(),
        title: String,
        parkID: String,
        landID: String,
        detailDescription: String,
        clueSuggestion: String,
        categorySuggestion: DiscoveryCategory? = nil,
        status: CommunitySubmissionStatus = .draft,
        createdAt: Date = Date(),
        submittedAt: Date? = nil,
        moderationNote: String? = nil
    ) {
        self.id = id
        self.title = title
        self.parkID = parkID
        self.landID = landID
        self.detailDescription = detailDescription
        self.clueSuggestion = clueSuggestion
        self.categorySuggestion = categorySuggestion
        self.status = status
        self.createdAt = createdAt
        self.submittedAt = submittedAt
        self.moderationNote = moderationNote
    }
}

enum CommunitySubmissionValidation {
    static func issues(
        for submission: CommunitySubmission
    ) -> [String] {
        var issues: [String] = []

        if submission.title.trimmingCharacters(in: .whitespacesAndNewlines).count < 4 {
            issues.append("Add a clear title.")
        }
        if submission.parkID.isEmpty {
            issues.append("Choose a park.")
        }
        if submission.landID.isEmpty {
            issues.append("Choose a land.")
        }
        if submission.detailDescription.trimmingCharacters(in: .whitespacesAndNewlines).count < 20 {
            issues.append("Describe the detail with enough context for an editor to verify it.")
        }
        if submission.clueSuggestion.trimmingCharacters(in: .whitespacesAndNewlines).count < 8 {
            issues.append("Add a useful clue suggestion.")
        }

        return issues
    }
}

protocol CommunitySubmissionStoring: AnyObject {
    func submissions() -> [CommunitySubmission]
    func save(_ submission: CommunitySubmission)
    func delete(id: UUID)
}

final class UserDefaultsCommunitySubmissionStore: CommunitySubmissionStoring {
    static let storageKey = "parkhunt.community-submissions.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func submissions() -> [CommunitySubmission] {
        guard let data = defaults.data(forKey: Self.storageKey),
              let values = try? JSONDecoder().decode(
                [CommunitySubmission].self,
                from: data
              ) else {
            return []
        }

        return values.sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ submission: CommunitySubmission) {
        var values = submissions()
        if let index = values.firstIndex(where: { $0.id == submission.id }) {
            values[index] = submission
        } else {
            values.append(submission)
        }

        guard let data = try? JSONEncoder().encode(values) else {
            return
        }
        defaults.set(data, forKey: Self.storageKey)
    }

    func delete(id: UUID) {
        let values = submissions().filter { $0.id != id }
        guard let data = try? JSONEncoder().encode(values) else {
            return
        }
        defaults.set(data, forKey: Self.storageKey)
    }
}

final class MemoryCommunitySubmissionStore: CommunitySubmissionStoring {
    private var values: [CommunitySubmission]

    init(_ values: [CommunitySubmission] = []) {
        self.values = values
    }

    func submissions() -> [CommunitySubmission] {
        values.sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ submission: CommunitySubmission) {
        if let index = values.firstIndex(where: { $0.id == submission.id }) {
            values[index] = submission
        } else {
            values.append(submission)
        }
    }

    func delete(id: UUID) {
        values.removeAll { $0.id == id }
    }
}

protocol CommunityModerationProviding: AnyObject {
    var isAvailable: Bool { get }
    func submit(_ submission: CommunitySubmission) throws -> CommunitySubmission
    func refresh(_ submission: CommunitySubmission) throws -> CommunitySubmission
}

enum CommunityModerationError: Error {
    case unavailable
}

final class NoopCommunityModerationProvider: CommunityModerationProviding {
    var isAvailable: Bool { false }

    func submit(
        _ submission: CommunitySubmission
    ) throws -> CommunitySubmission {
        throw CommunityModerationError.unavailable
    }

    func refresh(
        _ submission: CommunitySubmission
    ) throws -> CommunitySubmission {
        throw CommunityModerationError.unavailable
    }
}

final class MemoryCommunityModerationProvider: CommunityModerationProviding {
    var isAvailable: Bool
    private var remoteByID: [UUID: CommunitySubmission]

    init(
        isAvailable: Bool = true,
        remote: [CommunitySubmission] = []
    ) {
        self.isAvailable = isAvailable
        self.remoteByID = Dictionary(
            uniqueKeysWithValues: remote.map { ($0.id, $0) }
        )
    }

    func submit(
        _ submission: CommunitySubmission
    ) throws -> CommunitySubmission {
        guard isAvailable else {
            throw CommunityModerationError.unavailable
        }

        var submitted = submission
        submitted.status = .submitted
        submitted.submittedAt = submitted.submittedAt ?? Date()
        remoteByID[submitted.id] = submitted
        return submitted
    }

    func refresh(
        _ submission: CommunitySubmission
    ) throws -> CommunitySubmission {
        guard isAvailable else {
            throw CommunityModerationError.unavailable
        }

        return remoteByID[submission.id] ?? submission
    }

    func setModerated(_ submission: CommunitySubmission) {
        remoteByID[submission.id] = submission
    }
}

enum CommunitySubmissionResult: Equatable, Sendable {
    case savedDraft
    case submitted
    case refreshed
    case invalid([String])
    case unavailable
    case notEditable
}

protocol CommunitySubmissionServicing: AnyObject {
    var moderationAvailable: Bool { get }
    func submissions() -> [CommunitySubmission]
    func saveDraft(_ submission: CommunitySubmission) -> CommunitySubmissionResult
    func submit(id: UUID) -> CommunitySubmissionResult
    func refresh(id: UUID) -> CommunitySubmissionResult
    func deleteDraft(id: UUID)
}

final class CommunitySubmissionService: CommunitySubmissionServicing {
    private let store: any CommunitySubmissionStoring
    private let provider: any CommunityModerationProviding

    init(
        store: any CommunitySubmissionStoring,
        provider: any CommunityModerationProviding
    ) {
        self.store = store
        self.provider = provider
    }

    var moderationAvailable: Bool {
        provider.isAvailable
    }

    func submissions() -> [CommunitySubmission] {
        store.submissions()
    }

    func saveDraft(
        _ submission: CommunitySubmission
    ) -> CommunitySubmissionResult {
        guard submission.status == .draft else {
            return .notEditable
        }

        store.save(submission)
        return .savedDraft
    }

    func submit(id: UUID) -> CommunitySubmissionResult {
        guard let draft = store.submissions().first(where: { $0.id == id }),
              draft.status == .draft else {
            return .notEditable
        }

        let issues = CommunitySubmissionValidation.issues(for: draft)
        guard issues.isEmpty else {
            return .invalid(issues)
        }

        guard provider.isAvailable else {
            return .unavailable
        }

        do {
            let submitted = try provider.submit(draft)
            store.save(submitted)
            return .submitted
        } catch {
            return .unavailable
        }
    }

    func refresh(id: UUID) -> CommunitySubmissionResult {
        guard let current = store.submissions().first(where: { $0.id == id }),
              current.status != .draft else {
            return .notEditable
        }

        guard provider.isAvailable else {
            return .unavailable
        }

        do {
            let refreshed = try provider.refresh(current)
            store.save(refreshed)
            return .refreshed
        } catch {
            return .unavailable
        }
    }

    func deleteDraft(id: UUID) {
        guard let current = store.submissions().first(where: { $0.id == id }),
              current.status == .draft else {
            return
        }
        store.delete(id: id)
    }
}

// Intentionally no conversion from CommunitySubmission to Discovery.
// Approval means "ready for editorial review", never automatic publication.
