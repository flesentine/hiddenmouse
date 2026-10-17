import SwiftUI

@main
struct ParkHuntClipApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AppClipRootView(
                    contentLoader: ContentLoader()
                )
            }
        }
    }
}
