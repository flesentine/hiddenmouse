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
    let thumbnailImageName: String?
    let verificationStatus: VerificationStatus
    let lastVerifiedAt: Date?
    let isIndoor: Bool
    let tags: [String]

    init(
        id: String,
        title: String,
        parkID: String,
        landID: String,
        areaID: String?,
        category: DiscoveryCategory,
        difficulty: Difficulty,
        location: DiscoveryLocation?,
        hints: [Hint],
        revealDescription: String,
        revealImageName: String?,
        thumbnailImageName: String? = nil,
        verificationStatus: VerificationStatus,
        lastVerifiedAt: Date?,
        isIndoor: Bool,
        tags: [String]
    ) {
        self.id = id
        self.title = title
        self.parkID = parkID
        self.landID = landID
        self.areaID = areaID
        self.category = category
        self.difficulty = difficulty
        self.location = location
        self.hints = hints
        self.revealDescription = revealDescription
        self.revealImageName = revealImageName
        self.thumbnailImageName = thumbnailImageName
        self.verificationStatus = verificationStatus
        self.lastVerifiedAt = lastVerifiedAt
        self.isIndoor = isIndoor
        self.tags = tags
    }

    var sortedHints: [Hint] {
        hints.sorted {
            if $0.order == $1.order {
                return $0.id < $1.id
            }
            return $0.order < $1.order
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case parkID
        case landID
        case areaID
        case category
        case difficulty
        case location
        case hints
        case revealDescription
        case revealImageName
        case thumbnailImageName
        case verificationStatus
        case lastVerifiedAt
        case isIndoor
        case tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        parkID = try container.decode(String.self, forKey: .parkID)
        landID = try container.decode(String.self, forKey: .landID)
        areaID = try container.decodeIfPresent(String.self, forKey: .areaID)
        category = try container.decode(DiscoveryCategory.self, forKey: .category)
        difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
        location = try container.decodeIfPresent(DiscoveryLocation.self, forKey: .location)
        hints = try container.decode([Hint].self, forKey: .hints)
        revealDescription = try container.decode(String.self, forKey: .revealDescription)
        revealImageName = try container.decodeIfPresent(String.self, forKey: .revealImageName)
        thumbnailImageName = try container.decodeIfPresent(String.self, forKey: .thumbnailImageName)
        verificationStatus = try container.decode(
            VerificationStatus.self,
            forKey: .verificationStatus
        )
        lastVerifiedAt = try container.decodeIfPresent(
            Date.self,
            forKey: .lastVerifiedAt
        )
        isIndoor = try container.decode(Bool.self, forKey: .isIndoor)
        tags = try container.decode([String].self, forKey: .tags)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(parkID, forKey: .parkID)
        try container.encode(landID, forKey: .landID)
        try container.encodeIfPresent(areaID, forKey: .areaID)
        try container.encode(category, forKey: .category)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encode(hints, forKey: .hints)
        try container.encode(revealDescription, forKey: .revealDescription)
        try container.encodeIfPresent(revealImageName, forKey: .revealImageName)
        try container.encodeIfPresent(
            thumbnailImageName,
            forKey: .thumbnailImageName
        )
        try container.encode(verificationStatus, forKey: .verificationStatus)
        try container.encodeIfPresent(lastVerifiedAt, forKey: .lastVerifiedAt)
        try container.encode(isIndoor, forKey: .isIndoor)
        try container.encode(tags, forKey: .tags)
    }
}

struct Hint: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let order: Int
    let text: String
    let kind: HintKind?

    init(
        id: String,
        order: Int,
        text: String,
        kind: HintKind? = nil
    ) {
        self.id = id
        self.order = order
        self.text = text
        self.kind = kind
    }

    var resolvedKind: HintKind {
        kind ?? .clue
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case order
        case text
        case kind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        order = try container.decode(Int.self, forKey: .order)
        text = try container.decode(String.self, forKey: .text)
        kind = try container.decodeIfPresent(HintKind.self, forKey: .kind)
    }
}

enum HintKind: String, Codable, CaseIterable, Hashable, Sendable {
    case clue
    case detailed
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
