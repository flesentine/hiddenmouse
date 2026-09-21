import SwiftUI

struct RootView: View {
    let environment: AppEnvironment
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let spoilerPreferenceStore: any SpoilerPreferenceStoring

    var body: some View {
        NavigationStack {
            HomeView(
                contentLoader: contentLoader,
                spoilerPreferenceStore: spoilerPreferenceStore
            )
            .navigationDestination(for: String.self) { discoveryID in
                HuntView(
                    discoveryID: discoveryID,
                    contentLoader: contentLoader,
                    progressStore: progressStore,
                    spoilerPreferenceStore: spoilerPreferenceStore
                )
            }
        }
    }
}

#Preview {
    RootView(
        environment: .development,
        contentLoader: ContentLoader(),
        progressStore: MemoryUserProgressStore(),
        spoilerPreferenceStore: MemorySpoilerPreferenceStore()
    )
}
