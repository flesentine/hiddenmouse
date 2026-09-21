import SwiftUI

struct RootView: View {
    let environment: AppEnvironment
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring

    var body: some View {
        NavigationStack {
            HomeView(contentLoader: contentLoader)
                .navigationDestination(for: String.self) { discoveryID in
                    HuntView(
                        discoveryID: discoveryID,
                        contentLoader: contentLoader,
                        progressStore: progressStore
                    )
                }
        }
    }
}

#Preview {
    RootView(
        environment: .development,
        contentLoader: ContentLoader(),
        progressStore: MemoryUserProgressStore()
    )
}
