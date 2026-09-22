import SwiftUI

struct RootView: View {
    let environment: AppEnvironment
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let spoilerPreferenceStore: any SpoilerPreferenceStoring
    let hapticPreferenceStore: any HapticPreferenceStoring
    let activeHuntStore: any ActiveHuntStoring

    @State private var restorationSession: ActiveHuntSession?
    @State private var isPresentingRestoredHunt = false
    @State private var didAttemptRestoration = false

    var body: some View {
        NavigationStack {
            HomeView(
                contentLoader: contentLoader,
                progressStore: progressStore,
                spoilerPreferenceStore: spoilerPreferenceStore,
                hapticPreferenceStore: hapticPreferenceStore,
                activeHuntStore: activeHuntStore
            )
            .navigationDestination(for: String.self) { discoveryID in
                HuntView(
                    discoveryID: discoveryID,
                    contentLoader: contentLoader,
                    progressStore: progressStore,
                    spoilerPreferenceStore: spoilerPreferenceStore,
                    hapticPreferenceStore: hapticPreferenceStore,
                    activeHuntStore: activeHuntStore
                )
            }
            .navigationDestination(
                isPresented: $isPresentingRestoredHunt
            ) {
                if let restorationSession {
                    HuntView(
                        discoveryID: restorationSession.discoveryID,
                        contentLoader: contentLoader,
                        progressStore: progressStore,
                        spoilerPreferenceStore: spoilerPreferenceStore,
                        hapticPreferenceStore: hapticPreferenceStore,
                        activeHuntStore: activeHuntStore
                    )
                }
            }
        }
        .task {
            restoreActiveHuntIfNeeded()
        }
    }

    private func restoreActiveHuntIfNeeded() {
        guard !didAttemptRestoration else {
            return
        }

        didAttemptRestoration = true

        guard let storedSession = activeHuntStore.load() else {
            return
        }

        do {
            let snapshot = try contentLoader.load()
            let restorable = ActiveHuntRestorer.restorableSession(
                storedSession: storedSession,
                snapshot: snapshot,
                progress: progressStore.load()
            )

            guard let restorable else {
                activeHuntStore.clear()
                return
            }

            restorationSession = restorable
            isPresentingRestoredHunt = true
        } catch {
            // Preserve the session so a transient catalog-load failure
            // does not erase restoration state.
        }
    }
}

#Preview {
    RootView(
        environment: .development,
        contentLoader: ContentLoader(),
        progressStore: MemoryUserProgressStore(),
        spoilerPreferenceStore: MemorySpoilerPreferenceStore(),
        hapticPreferenceStore: MemoryHapticPreferenceStore(),
        activeHuntStore: MemoryActiveHuntStore()
    )
}
