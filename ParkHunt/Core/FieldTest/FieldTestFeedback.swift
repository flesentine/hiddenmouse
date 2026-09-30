import Foundation

enum FieldTestAccuracyRating: String, Codable, CaseIterable, Identifiable, Sendable {
    case wrong
    case close
    case accurate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wrong: "Wrong"
        case .close: "Close"
        case .accurate: "Accurate"
        }
    }
}

enum FieldTestClueRating: String, Codable, CaseIterable, Identifiable, Sendable {
    case confusing
    case workable
    case clear

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .confusing: "Confusing"
        case .workable: "Okay"
        case .clear: "Clear"
        }
    }
}

enum FieldTestNearbyRating: String, Codable, CaseIterable, Identifiable, Sendable {
    case notUsed
    case poor
    case okay
    case useful

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notUsed: "Not used"
        case .poor: "Poor"
        case .okay: "Okay"
        case .useful: "Useful"
        }
    }
}

enum FieldTestIssue: String, Codable, CaseIterable, Identifiable, Sendable {
    case locationWrong
    case clueConfusing
    case revealWrong
    case nearbyRanking
    case inaccessible
    case duplicate
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .locationWrong: "Location is wrong"
        case .clueConfusing: "Clue is confusing"
        case .revealWrong: "Reveal is wrong"
        case .nearbyRanking: "Nearby ordering is poor"
        case .inaccessible: "Spot is inaccessible"
        case .duplicate: "Looks duplicated"
        case .other: "Other issue"
        }
    }
}

struct FieldTestFeedbackRecord: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let discoveryID: String
    let discoveryTitle: String
    let accuracy: FieldTestAccuracyRating
    let clueQuality: FieldTestClueRating
    let nearbyUsefulness: FieldTestNearbyRating
    let issues: [FieldTestIssue]
    let notes: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        discoveryID: String,
        discoveryTitle: String,
        accuracy: FieldTestAccuracyRating,
        clueQuality: FieldTestClueRating,
        nearbyUsefulness: FieldTestNearbyRating,
        issues: [FieldTestIssue] = [],
        notes: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.discoveryID = discoveryID
        self.discoveryTitle = discoveryTitle
        self.accuracy = accuracy
        self.clueQuality = clueQuality
        self.nearbyUsefulness = nearbyUsefulness
        self.issues = Array(Set(issues)).sorted { $0.rawValue < $1.rawValue }
        self.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

protocol FieldTestFeedbackStoring: AnyObject {
    func save(_ record: FieldTestFeedbackRecord)
    func records() -> [FieldTestFeedbackRecord]
    func clear()
}

final class UserDefaultsFieldTestFeedbackStore: FieldTestFeedbackStoring {
    static let defaultStorageKey = "parkhunt.field-test.feedback.v1"
    static let defaultMaximumRecordCount = 500

    private let defaults: UserDefaults
    private let storageKey: String
    private let maximumRecordCount: Int

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = defaultStorageKey,
        maximumRecordCount: Int = defaultMaximumRecordCount
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.maximumRecordCount = max(maximumRecordCount, 1)
    }

    func save(_ record: FieldTestFeedbackRecord) {
        var stored = records()
        stored.insert(record, at: 0)

        if stored.count > maximumRecordCount {
            stored = Array(stored.prefix(maximumRecordCount))
        }

        guard let data = try? JSONEncoder().encode(stored) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }

    func records() -> [FieldTestFeedbackRecord] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(
                [FieldTestFeedbackRecord].self,
                from: data
              ) else {
            return []
        }

        return decoded.sorted { $0.timestamp > $1.timestamp }
    }

    func clear() {
        defaults.removeObject(forKey: storageKey)
    }

    func exportJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(records()),
              let text = String(data: data, encoding: .utf8) else {
            return "[]"
        }

        return text
    }
}

final class MemoryFieldTestFeedbackStore: FieldTestFeedbackStoring {
    private var stored: [FieldTestFeedbackRecord]

    init(records: [FieldTestFeedbackRecord] = []) {
        stored = records
    }

    func save(_ record: FieldTestFeedbackRecord) {
        stored.append(record)
    }

    func records() -> [FieldTestFeedbackRecord] {
        stored.sorted { $0.timestamp > $1.timestamp }
    }

    func clear() {
        stored = []
    }
}
