import SwiftUI
import UIKit

struct SettingsView: View {
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let spoilerPreferenceStore: any SpoilerPreferenceStoring
    let hapticPreferenceStore: any HapticPreferenceStoring
    let activeHuntStore: any ActiveHuntStoring
    let analyticsRecorder: any AnalyticsRecording
    let analyticsPreferenceStore: any AnalyticsPreferenceStoring
    let premiumEntitlementStore: any PremiumEntitlementStoring
    let cloudSyncService: any CloudSyncServicing
    let familySharingService: any FamilySharingServicing

    @StateObject private var locationPermission = LocationPermissionController()
    @Environment(\.openURL) private var openURL

    @State private var helpStyle: SpoilerPreference = .normal
    @State private var hapticsEnabled = true
    @State private var localAnalyticsEnabled = true
    @State private var analyticsEventCount = 0
    @State private var fieldFeedbackCount = 0
    @State private var premiumEntitlement: PremiumEntitlement = .free
    @State private var cloudSyncAvailability: CloudSyncAvailability = .unavailable
    @State private var cloudSyncMessage: String?
    @State private var showResetConfirmation = false
    @State private var showClearAnalyticsConfirmation = false
    @State private var didResetProgress = false
    @State private var didClearAnalytics = false

    private let appInfo = AppInfo.current

    var body: some View {
        List {
            locationSection
            gameplaySection
            premiumSection
            cloudSyncSection
            familySection

            if AppEnvironment.current == .fieldTest {
                fieldTestSection
            }

            privacySection
            dataSection
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            helpStyle = spoilerPreferenceStore.load()
            hapticsEnabled = hapticPreferenceStore.load()
            localAnalyticsEnabled = analyticsPreferenceStore.load()
            premiumEntitlement = premiumEntitlementStore.load()
            cloudSyncAvailability = cloudSyncService.availability()
            refreshAnalyticsCount()
            refreshFieldFeedbackCount()
        }
        .alert(
            "Reset Hunt Progress?",
            isPresented: $showResetConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Progress", role: .destructive) {
                progressStore.reset()
                activeHuntStore.clear()
                didResetProgress = true
            }
        } message: {
            Text(
                "This clears found hunts, clue progress, reveal history, and progress timestamps on this device. Help Style, haptics, and local analytics data will not change."
            )
        }
        .alert(
            "Clear Local Analytics?",
            isPresented: $showClearAnalyticsConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Analytics", role: .destructive) {
                analyticsRecorder.clear()
                refreshAnalyticsCount()
                didClearAnalytics = true
            }
        } message: {
            Text(
                "This permanently deletes the locally stored product-use events on this device. It does not affect hunt progress."
            )
        }
    }

    private var locationSection: some View {
        Section {
            HStack {
                Label("Location", systemImage: "location")

                Spacer()

                Text(locationStatusText)
                    .foregroundStyle(.secondary)
            }

            switch locationPermission.state {
            case .notDetermined:
                NavigationLink {
                    NearbyPermissionView(
                        contentLoader: contentLoader,
                        progressStore: progressStore,
                        huntRouteDependencies: huntRouteDependencies
                    )
                } label: {
                    Label(
                        "Set Up Nearby",
                        systemImage: "location.circle"
                    )
                }

            case .authorized, .denied:
                Button {
                    openSystemSettings()
                } label: {
                    Label(
                        "Open iOS Settings",
                        systemImage: "gear"
                    )
                }

            case .restricted:
                EmptyView()
            }
        } header: {
            Text("Location")
        } footer: {
            Text(
                "Park Hunt asks for When In Use access only from Nearby. Coordinates are used only for the current foreground check, are never saved, and are discarded when Nearby closes or the app backgrounds."
            )
        }
    }

    private var huntRouteDependencies: HuntRouteDependencies {
        HuntRouteDependencies(
            contentLoader: contentLoader,
            progressStore: progressStore,
            spoilerPreferenceStore: spoilerPreferenceStore,
            hapticPreferenceStore: hapticPreferenceStore,
            activeHuntStore: activeHuntStore,
            analyticsRecorder: analyticsRecorder
        )
    }

    private var gameplaySection: some View {
        Section("Gameplay") {
            NavigationLink {
                SpoilerSettingsView(
                    store: spoilerPreferenceStore
                )
            } label: {
                HStack {
                    Label(
                        "Help Style",
                        systemImage: helpStyle.systemImageName
                    )

                    Spacer()

                    Text(helpStyle.displayName)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(
                isOn: Binding(
                    get: { hapticsEnabled },
                    set: { newValue in
                        hapticsEnabled = newValue
                        hapticPreferenceStore.save(newValue)
                    }
                )
            ) {
                Label(
                    "Haptics",
                    systemImage: "waveform"
                )
            }
            .accessibilityHint(
                "Controls tactile feedback for clues, stronger help, full reveal, and found success"
            )
        }
    }

    private var premiumSection: some View {
        Section {
            NavigationLink {
                PremiumUpgradeView(
                    entitlementStore: premiumEntitlementStore
                )
            } label: {
                HStack {
                    Label(
                        "Park Hunt Premium",
                        systemImage: premiumEntitlement.isPremium
                            ? "checkmark.seal.fill"
                            : "star"
                    )

                    Spacer()

                    Text(
                        premiumEntitlement.isPremium
                            ? "Active"
                            : "Free"
                    )
                    .foregroundStyle(.secondary)
                }
            }

            if AppEnvironment.current != .production {
                Toggle(
                    "Premium Test Override",
                    isOn: Binding(
                        get: { premiumEntitlement.isPremium },
                        set: { enabled in
                            premiumEntitlement = enabled
                                ? .premium
                                : .free
                            premiumEntitlementStore.save(
                                premiumEntitlement
                            )
                        }
                    )
                )
                .accessibilityHint(
                    "Development-only control for testing premium feature gates"
                )
            }
        } header: {
            Text("Premium")
        } footer: {
            Text(
                AppEnvironment.current == .production
                    ? "Premium access is controlled by the purchase entitlement provider."
                    : "The test override is available only in development and field-test builds."
            )
        }
    }

    private var cloudSyncSection: some View {
        Section {
            HStack {
                Label("Cloud Sync", systemImage: "icloud")

                Spacer()

                Text(cloudSyncStatusText)
                    .foregroundStyle(.secondary)
            }

            if case .ready = cloudSyncAvailability {
                Button {
                    let result = cloudSyncService.sync()
                    cloudSyncAvailability = cloudSyncService.availability()
                    cloudSyncMessage = cloudSyncResultText(result)
                } label: {
                    Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            if let cloudSyncMessage {
                Text(cloudSyncMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Account & Sync")
        } footer: {
            Text(
                "Cloud sync is optional. Park Hunt always saves progress locally and remains fully usable without an account or network connection."
            )
        }
    }

    private var familySection: some View {
        Section {
            NavigationLink {
                FamilySharingView(
                    contentLoader: contentLoader,
                    service: familySharingService
                )
            } label: {
                HStack {
                    Label("Family", systemImage: "person.3")

                    Spacer()

                    Text(familyStatusText)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Family")
        } footer: {
            Text(
                "Family sharing is optional and keeps personal clue, reveal, location, timestamp, and analytics data private."
            )
        }
    }

    private var fieldTestSection: some View {
        Section {
            NavigationLink {
                FieldTestFeedbackLogView()
            } label: {
                HStack {
                    Label(
                        "Field Test Feedback",
                        systemImage: "testtube.2"
                    )

                    Spacer()

                    Text("\(fieldFeedbackCount)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        } header: {
            Text("Field Test")
        } footer: {
            Text(
                "Feedback is stored only on this device and can be shared as structured JSON from the feedback screen."
            )
        }
    }

    private var privacySection: some View {
        Section {
            Toggle(
                isOn: Binding(
                    get: { localAnalyticsEnabled },
                    set: { newValue in
                        localAnalyticsEnabled = newValue
                        analyticsPreferenceStore.save(newValue)
                        didClearAnalytics = false
                    }
                )
            ) {
                Label(
                    "Local Analytics",
                    systemImage: "chart.bar"
                )
            }
            .accessibilityHint(
                "Controls whether Park Hunt records new product-use events locally on this device"
            )

            HStack {
                Label(
                    "Stored Analytics",
                    systemImage: "internaldrive"
                )

                Spacer()

                Text(
                    "\(analyticsEventCount) event\(analyticsEventCount == 1 ? "" : "s")"
                )
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }

            Button(role: .destructive) {
                showClearAnalyticsConfirmation = true
            } label: {
                Label(
                    "Clear Analytics Data",
                    systemImage: "trash"
                )
            }
            .disabled(analyticsEventCount == 0)

            if didClearAnalytics {
                Label(
                    "Local analytics cleared",
                    systemImage: "checkmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } header: {
            Text("Privacy")
        } footer: {
            Text(
                "Analytics stay on this device, never include precise location, and are automatically removed after 30 days. Turning this off stops new events; clearing deletes stored events now."
            )
        }
    }

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label(
                    "Reset Hunt Progress",
                    systemImage: "arrow.counterclockwise"
                )
            }

            if didResetProgress {
                Label(
                    "Hunt progress reset",
                    systemImage: "checkmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } header: {
            Text("Data")
        } footer: {
            Text(
                "Reset affects only hunt history on this device. Analytics data is managed separately in Privacy."
            )
        }
    }

    private var aboutSection: some View {
        Section("About") {
            if let buildChannelText = AppEnvironment.current.buildChannelText {
                Label(
                    buildChannelText,
                    systemImage: "testtube.2"
                )
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier("settings.field-test")
            }

            HStack {
                Label("Park Hunt", systemImage: "scope")

                Spacer()

                Text(appInfo.versionBuildText)
                    .foregroundStyle(.secondary)
            }

            NavigationLink {
                LegalInfoView()
            } label: {
                Label(
                    "Privacy & Legal",
                    systemImage: "hand.raised"
                )
            }
        }
    }

    private var familyStatusText: String {
        switch familySharingService.availability() {
        case .unavailable:
            "Not Connected"
        case .notMember:
            "No Group"
        case .ready:
            "Connected"
        }
    }

    private var cloudSyncStatusText: String {
        switch cloudSyncAvailability {
        case .unavailable:
            "Not Connected"
        case .signedOut:
            "Signed Out"
        case let .ready(account):
            account.displayName ?? "Connected"
        }
    }

    private func cloudSyncResultText(
        _ result: CloudSyncResult
    ) -> String {
        switch result {
        case .signedOut:
            "Sign in to sync progress."
        case .unavailable:
            "Cloud sync provider is not available in this build."
        case .uploaded:
            "Local progress uploaded."
        case .merged:
            "Local and cloud progress merged."
        }
    }

    private var locationStatusText: String {
        switch locationPermission.state {
        case .notDetermined:
            "Not Requested"
        case .authorized:
            "When In Use"
        case .denied:
            "Off"
        case .restricted:
            "Restricted"
        }
    }

    private func refreshAnalyticsCount() {
        analyticsEventCount = analyticsRecorder.events().count
    }

    private func refreshFieldFeedbackCount() {
        fieldFeedbackCount = UserDefaultsFieldTestFeedbackStore().records().count
    }

    private func openSystemSettings() {
        guard let url = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        openURL(url)
    }
}

#Preview {
    let analyticsPreference = MemoryAnalyticsPreferenceStore()

    NavigationStack {
        SettingsView(
            contentLoader: ContentLoader(),
            progressStore: MemoryUserProgressStore(),
            spoilerPreferenceStore: MemorySpoilerPreferenceStore(),
            hapticPreferenceStore: MemoryHapticPreferenceStore(),
            activeHuntStore: MemoryActiveHuntStore(),
            analyticsRecorder: MemoryAnalyticsRecorder(
                preferenceStore: analyticsPreference
            ),
            analyticsPreferenceStore: analyticsPreference,
            premiumEntitlementStore: MemoryPremiumEntitlementStore(),
            cloudSyncService: CloudSyncService(
                localStore: MemoryUserProgressStore(),
                accountProvider: NoopCloudAccountProvider(),
                cloudStore: NoopCloudProgressStore()
            ),
            familySharingService: FamilySharingService(
                personalProgressStore: MemoryUserProgressStore(),
                provider: NoopFamilySharingProvider()
            )
        )
    }
}
