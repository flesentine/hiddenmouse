import Foundation

struct Discovery: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let parkID: String
    let landID: String
    let areaID: String?
    let category: DiscoveryCategory
    let difficulty: Difficulty
    let location: DiscoveryLocation?
    let hints: [Hint]
    let revealDescription: String
    let revealImageName: String?
    let verificationStatus: VerificationStatus
    let lastVerifiedAt: Date?
    let isIndoor: Bool
    let tags: [String]

    var sortedHints: [Hint] {
        hints.sorted {
            if $0.order == $1.order {
                return $0.id < $1.id
            }
            return $0.order < $1.order
        }
    }
}

struct Hint: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let order: Int
    let text: String
}

enum Difficulty: String, Codable, CaseIterable, Hashable, Sendable {
    case easy
    case medium
    case hard
    case expert

    var rank: Int {
        switch self {
        case .easy: 1
        case .medium: 2
        case .hard: 3
        case .expert: 4
        }
    }
}

enum DiscoveryCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case hiddenMickey
    case hiddenCharacter
    case imagineeringDetail
    case movieReference
    case historicalDetail
    case easterEgg
    case secretFeature
}

enum VerificationStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case verified
    case needsRecheck
    case unverified
    case temporarilyUnavailable
    case removed
}

struct DiscoveryLocation: Codable, Equatable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    /// Approximate discovery/area radius. The product must not imply indoor GPS
    /// is accurate enough to prove a user found a specific detail.
    let radiusMeters: Double
}
