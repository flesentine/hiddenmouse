import SwiftUI

struct RootView: View {
    let environment: AppEnvironment
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let spoilerPreferenceStore: any SpoilerPreferenceStoring
    let hapticPreferenceStore: any HapticPreferenceStoring
    let activeHuntStore: any ActiveHuntStoring
    let analyticsRecorder: any AnalyticsRecording

    @State private var restorationSession: ActiveHuntSession?
    @State private var isPresentingRestoredHunt = false
    @State private var didAttemptRestoration = false
    @State private var didRecordAppOpen = false

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
                    activeHuntStore: activeHuntStore,
                    analyticsRecorder: analyticsRecorder
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
                        activeHuntStore: activeHuntStore,
                        analyticsRecorder: analyticsRecorder,
                        launchContext: .restored
                    )
                }
            }
        }
        .task {
            recordAppOpenIfNeeded()
            restoreActiveHuntIfNeeded()
        }
    }

    private func recordAppOpenIfNeeded() {
        guard !didRecordAppOpen else {
            return
        }

        didRecordAppOpen = true
        analyticsRecorder.record(.appOpen())
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

            if let discovery = snapshot.discovery(
                id: restorable.discoveryID
            ) {
                analyticsRecorder.record(
                    .activeHuntRestored(
                        discovery: discovery,
                        revealWasOpen: restorable.isRevealPresented
                    )
                )
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
        activeHuntStore: MemoryActiveHuntStore(),
        analyticsRecorder: MemoryAnalyticsRecorder()
    )
}
