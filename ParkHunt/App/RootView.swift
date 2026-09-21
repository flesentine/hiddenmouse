import SwiftUI

struct RootView: View {
    let environment: AppEnvironment
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let spoilerPreferenceStore: any SpoilerPreferenceStoring
    let hapticPreferenceStore: any HapticPreferenceStoring

    var body: some View {
        NavigationStack {
            HomeView(
                contentLoader: contentLoader,
                progressStore: progressStore,
                spoilerPreferenceStore: spoilerPreferenceStore,
                hapticPreferenceStore: hapticPreferenceStore
            )
            .navigationDestination(for: String.self) { discoveryID in
                HuntView(
                    discoveryID: discoveryID,
                    contentLoader: contentLoader,
                    progressStore: progressStore,
                    spoilerPreferenceStore: spoilerPreferenceStore,
                    hapticPreferenceStore: hapticPreferenceStore
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
        spoilerPreferenceStore: MemorySpoilerPreferenceStore(),
        hapticPreferenceStore: MemoryHapticPreferenceStore()
    )
}
