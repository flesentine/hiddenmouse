import SwiftUI

@main
struct ParkHuntApp: App {
    private let environment = AppEnvironment.current
    private let contentLoader = ContentLoader()
    private let progressStore = UserDefaultsUserProgressStore()
    private let spoilerPreferenceStore = UserDefaultsSpoilerPreferenceStore()
    private let hapticPreferenceStore = UserDefaultsHapticPreferenceStore()

    var body: some Scene {
        WindowGroup {
            RootView(
                environment: environment,
                contentLoader: contentLoader,
                progressStore: progressStore,
                spoilerPreferenceStore: spoilerPreferenceStore,
                hapticPreferenceStore: hapticPreferenceStore
            )
        }
    }
}
