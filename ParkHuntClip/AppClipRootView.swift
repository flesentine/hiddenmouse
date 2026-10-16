import SwiftUI

struct AppClipRootView: View {
    let contentLoader: ContentLoader

    @State private var entry: AppClipEntry?
    @State private var discoveryID: String?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let discoveryID {
                AppClipHuntView(
                    discoveryID: discoveryID,
                    contentLoader: contentLoader
                )
            } else if loadFailed {
                ContentUnavailableView(
                    "Hunt Unavailable",
                    systemImage: "binoculars",
                    description: Text(
                        "This App Clip link does not point to an available hunt."
                    )
                )
            } else {
                ContentUnavailableView(
                    "Open a Park Hunt Link",
                    systemImage: "scope",
                    description: Text(
                        "Scan or open a Park Hunt App Clip link to launch a single hunt."
                    )
                )
            }
        }
        .onOpenURL { url in
            handle(AppClipEntryResolver.resolve(url: url))
        }
        .onContinueUserActivity(
            NSUserActivityTypeBrowsingWeb
        ) { activity in
            handle(
                AppClipEntryResolver.resolve(
                    userActivity: activity
                )
            )
        }
    }

    private func handle(_ resolved: AppClipEntry?) {
        guard let resolved else {
            loadFailed = true
            discoveryID = nil
            return
        }

        entry = resolved

        do {
            let snapshot = try contentLoader.load()
            discoveryID = AppClipEntryResolver.validatedDiscoveryID(
                from: resolved,
                snapshot: snapshot
            )
            loadFailed = discoveryID == nil
        } catch {
            discoveryID = nil
            loadFailed = true
        }
    }
}
