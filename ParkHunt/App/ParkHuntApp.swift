import SwiftUI

@main
struct ParkHuntApp: App {
    private let environment = AppEnvironment.current
    private let contentLoader: ContentLoader
    private let remoteContentService: any RemoteContentServicing
    private let progressStore = UserDefaultsUserProgressStore()
    private let spoilerPreferenceStore = UserDefaultsSpoilerPreferenceStore()
    private let hapticPreferenceStore = UserDefaultsHapticPreferenceStore()
    private let activeHuntStore = UserDefaultsActiveHuntStore()
    private let premiumEntitlementStore = UserDefaultsPremiumEntitlementStore()
    private let analyticsPreferenceStore:
        UserDefaultsAnalyticsPreferenceStore
    private let analyticsRecorder:
        UserDefaultsAnalyticsRecorder

    private var communitySubmissionService: any CommunitySubmissionServicing {
        CommunitySubmissionService(
            store: UserDefaultsCommunitySubmissionStore(),
            provider: NoopCommunityModerationProvider()
        )
    }

    private var familySharingService: any FamilySharingServicing {
        FamilySharingService(
            personalProgressStore: progressStore,
            provider: NoopFamilySharingProvider()
        )
    }

    private var cloudSyncService: any CloudSyncServicing {
        CloudSyncService(
            localStore: progressStore,
            accountProvider: NoopCloudAccountProvider(),
            cloudStore: NoopCloudProgressStore()
        )
    }

    private var advertisingProvider: any AdvertisingProviding {
        switch environment {
        case .development, .fieldTest:
            PreviewAdvertisingProvider()
        case .production:
            NoopAdvertisingProvider()
        }
    }

    init() {
        UITestSupport.prepareLaunch()

        let remoteContent = RemoteContentFactory.makeProduction()
        contentLoader = remoteContent.loader
        remoteContentService = remoteContent.service

        let preferenceStore =
            UserDefaultsAnalyticsPreferenceStore()
        analyticsPreferenceStore = preferenceStore
        analyticsRecorder = UserDefaultsAnalyticsRecorder(
            preferenceStore: preferenceStore
        )
    }

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
                analyticsPreferenceStore: analyticsPreferenceStore,
                premiumEntitlementStore: premiumEntitlementStore,
                advertisingProvider: advertisingProvider,
                cloudSyncService: cloudSyncService,
                familySharingService: familySharingService,
                communitySubmissionService: communitySubmissionService,
                remoteContentService: remoteContentService
            )
        }
    }
}
