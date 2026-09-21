import Foundation

enum SpoilerPreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case explorer
    case normal
    case helpMe
    case showMe

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .explorer:
            "Explorer"
        case .normal:
            "Normal"
        case .helpMe:
            "Help Me"
        case .showMe:
            "Show Me"
        }
    }

    var description: String {
        switch self {
        case .explorer:
            "Keep help subtle so you spend more time searching on your own."
        case .normal:
            "Offer the next clue one step at a time."
        case .helpMe:
            "Make stronger help easier to reach when you get stuck."
        case .showMe:
            "Keep the full reveal one tap away."
        }
    }

    var systemImageName: String {
        switch self {
        case .explorer:
            "binoculars"
        case .normal:
            "lightbulb"
        case .helpMe:
            "lifepreserver"
        case .showMe:
            "eye"
        }
    }
}
