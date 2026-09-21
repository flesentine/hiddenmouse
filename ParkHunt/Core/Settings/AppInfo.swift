import Foundation

struct AppInfo: Equatable, Sendable {
    let version: String
    let build: String

    static var current: AppInfo {
        AppInfo(
            version: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? "0.1.0",
            build: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleVersion"
            ) as? String ?? "1"
        )
    }

    var versionBuildText: String {
        "Version \(version) (\(build))"
    }
}
