import Foundation

enum AnalyticsEventName: String, Codable, Equatable, Sendable {
    case appOpen
    case huntStarted
    case activeHuntRestored
    case clueRevealed
    case detailedHelpRevealed
    case fullRevealOpened
    case discoveryFound
    case findAnotherTapped
    case huntExitedUnfinished
}

enum AnalyticsHuntLaunchContext: Equatable, Sendable {
    case standard
    case restored
}

struct AnalyticsEventRecord: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let name: AnalyticsEventName
    let timestamp: Date
    let discoveryID: String?
    let landID: String?
    let category: DiscoveryCategory?
    let difficulty: Difficulty?
    let hintOrder: Int?
    let hintKind: HintKind?
    let nextDiscoveryID: String?
    let restoredRevealWasOpen: Bool?

    private init(
        id: UUID = UUID(),
        name: AnalyticsEventName,
        timestamp: Date,
        discoveryID: String? = nil,
        landID: String? = nil,
        category: DiscoveryCategory? = nil,
        difficulty: Difficulty? = nil,
        hintOrder: Int? = nil,
        hintKind: HintKind? = nil,
        nextDiscoveryID: String? = nil,
        restoredRevealWasOpen: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.discoveryID = discoveryID
        self.landID = landID
        self.category = category
        self.difficulty = difficulty
        self.hintOrder = hintOrder
        self.hintKind = hintKind
        self.nextDiscoveryID = nextDiscoveryID
        self.restoredRevealWasOpen = restoredRevealWasOpen
    }

    static func appOpen(
        at date: Date = Date()
    ) -> AnalyticsEventRecord {
        AnalyticsEventRecord(
            name: .appOpen,
            timestamp: date
        )
    }

    static func huntStarted(
        discovery: Discovery,
        at date: Date = Date()
    ) -> AnalyticsEventRecord {
        discoveryEvent(
            name: .huntStarted,
            discovery: discovery,
            date: date
        )
    }

    static func activeHuntRestored(
        discovery: Discovery,
        revealWasOpen: Bool,
        at date: Date = Date()
    ) -> AnalyticsEventRecord {
        discoveryEvent(
            name: .activeHuntRestored,
            discovery: discovery,
            date: date,
            restoredRevealWasOpen: revealWasOpen
        )
    }

    static func assistAction(
        _ action: HuntProgressionAction,
        discovery: Discovery,
        at date: Date = Date()
    ) -> AnalyticsEventRecord {
        switch action {
        case let .revealHint(hint):
            return AnalyticsEventRecord(
                name: hint.resolvedKind == .detailed
                    ? .detailedHelpRevealed
                    : .clueRevealed,
                timestamp: date,
                discoveryID: discovery.id,
                landID: discovery.landID,
                category: discovery.category,
                difficulty: discovery.difficulty,
                hintOrder: hint.order,
                hintKind: hint.resolvedKind
            )

        case .revealLocation:
            return discoveryEvent(
                name: .fullRevealOpened,
                discovery: discovery,
                date: date
            )
        }
    }

    static func discoveryFound(
        discovery: Discovery,
        at date: Date = Date()
    ) -> AnalyticsEventRecord {
        discoveryEvent(
            name: .discoveryFound,
            discovery: discovery,
            date: date
        )
    }

    static func findAnotherTapped(
        currentDiscovery: Discovery,
        nextDiscoveryID: String,
        at date: Date = Date()
    ) -> AnalyticsEventRecord {
        discoveryEvent(
            name: .findAnotherTapped,
            discovery: currentDiscovery,
            date: date,
            nextDiscoveryID: nextDiscoveryID
        )
    }

    static func huntExitedUnfinished(
        discovery: Discovery,
        at date: Date = Date()
    ) -> AnalyticsEventRecord {
        discoveryEvent(
            name: .huntExitedUnfinished,
            discovery: discovery,
            date: date
        )
    }

    private static func discoveryEvent(
        name: AnalyticsEventName,
        discovery: Discovery,
        date: Date,
        nextDiscoveryID: String? = nil,
        restoredRevealWasOpen: Bool? = nil
    ) -> AnalyticsEventRecord {
        AnalyticsEventRecord(
            name: name,
            timestamp: date,
            discoveryID: discovery.id,
            landID: discovery.landID,
            category: discovery.category,
            difficulty: discovery.difficulty,
            nextDiscoveryID: nextDiscoveryID,
            restoredRevealWasOpen: restoredRevealWasOpen
        )
    }
}
