import Foundation

enum AppClipEntry: Equatable, Sendable {
    case hunt(discoveryID: String)
}

enum AppClipEntryResolver {
    static func resolve(url: URL) -> AppClipEntry? {
        let components = url.pathComponents.filter { $0 != "/" }

        guard components.count >= 2,
              components[0].lowercased() == "hunt" else {
            return nil
        }

        let id = components[1]
            .removingPercentEncoding?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? components[1]

        guard !id.isEmpty else {
            return nil
        }

        return .hunt(discoveryID: id)
    }

    static func resolve(
        userActivity: NSUserActivity
    ) -> AppClipEntry? {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return nil
        }

        return resolve(url: url)
    }

    static func validatedDiscoveryID(
        from entry: AppClipEntry,
        snapshot: ContentSnapshot
    ) -> String? {
        switch entry {
        case let .hunt(discoveryID):
            return snapshot.discovery(id: discoveryID)?.id
        }
    }
}
