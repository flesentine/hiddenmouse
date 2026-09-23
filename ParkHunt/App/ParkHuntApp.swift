import SwiftUI

@main
struct ParkHuntApp: App {
    private let environment = AppEnvironment.current
    private let contentLoader = ContentLoader()
    private let progressStore = UserDefaultsUserProgressStore()
    private let spoilerPreferenceStore = UserDefaultsSpoilerPreferenceStore()
    private let hapticPreferenceStore = UserDefaultsHapticPreferenceStore()
    private let activeHuntStore = UserDefaultsActiveHuntStore()
    private let analyticsPreferenceStore =
        UserDefaultsAnalyticsPreferenceStore()
    private let analyticsRecorder = UserDefaultsAnalyticsRecorder()

    var body: some Scene {
        WindowGroup {
            RootView(
                environment: environment,
                contentLoader: contentLoader,
                progressStore: progressStore,
                spoilerPreferenceStore: spoilerPreferenceStore,
                hapticPreferenceStore: hapticPreferenceStore,
                activeHuntStore: activeHuntStore,
                analyticsRecorder: analyticsRecorder,
                analyticsPreferenceStore: analyticsPreferenceStore
            )
        }
    }
}
