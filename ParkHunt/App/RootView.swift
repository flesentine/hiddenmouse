import SwiftUI

struct RootView: View {
    let environment: AppEnvironment
    let contentLoader: ContentLoader

    var body: some View {
        NavigationStack {
            HomeView(contentLoader: contentLoader)
                .navigationDestination(for: String.self) { discoveryID in
                    HuntView(
                        discoveryID: discoveryID,
                        contentLoader: contentLoader
                    )
                }
        }
    }
}

#Preview {
    RootView(
        environment: .development,
        contentLoader: ContentLoader()
    )
}
