struct HuntRouteDependencies {
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let spoilerPreferenceStore: any SpoilerPreferenceStoring
    let hapticPreferenceStore: any HapticPreferenceStoring
    let activeHuntStore: any ActiveHuntStoring
    let analyticsRecorder: any AnalyticsRecording

    func makeHuntView(
        discoveryID: String,
        launchContext: AnalyticsHuntLaunchContext = .standard
    ) -> HuntView {
        HuntView(
            discoveryID: discoveryID,
            contentLoader: contentLoader,
            progressStore: progressStore,
            spoilerPreferenceStore: spoilerPreferenceStore,
            hapticPreferenceStore: hapticPreferenceStore,
            activeHuntStore: activeHuntStore,
            analyticsRecorder: analyticsRecorder,
            launchContext: launchContext
        )
    }

    static var preview: HuntRouteDependencies {
        HuntRouteDependencies(
            contentLoader: ContentLoader(),
            progressStore: MemoryUserProgressStore(),
            spoilerPreferenceStore: MemorySpoilerPreferenceStore(),
            hapticPreferenceStore: MemoryHapticPreferenceStore(),
            activeHuntStore: MemoryActiveHuntStore(),
            analyticsRecorder: MemoryAnalyticsRecorder()
        )
    }
}
