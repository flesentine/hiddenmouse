import Foundation

enum AppEnvironment: String, Sendable {
    case development
    case production

    static var current: Self {
        #if PARKHUNT_DEVELOPMENT
        return .development
        #else
        return .production
        #endif
    }

    var apiBaseURL: URL? { nil }
    var analyticsEnabled: Bool { false }
}
