import Foundation

enum AppEnvironment: String, Sendable {
    case development
    case fieldTest
    case production

    static var current: Self {
        #if PARKHUNT_FIELD_TEST
        return .fieldTest
        #elseif PARKHUNT_DEVELOPMENT
        return .development
        #else
        return .production
        #endif
    }

    var apiBaseURL: URL? { nil }
    var analyticsEnabled: Bool { false }

    var areaBadgeText: String {
        switch self {
        case .development:
            "Prototype area"
        case .fieldTest:
            "Disneyland field-test area"
        case .production:
            "Featured area"
        }
    }

    var buildChannelText: String? {
        switch self {
        case .fieldTest:
            "Disneyland Field Test"
        case .development, .production:
            nil
        }
    }
}
