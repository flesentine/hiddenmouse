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

    @StateObject private var locationPermission = LocationPermissionController()
    @Environment(\.openURL) private var openURL

    @State private var helpStyle: SpoilerPreference = .normal
    @State private var hapticsEnabled = true
    @State private var localAnalyticsEnabled = true
    @State private var analyticsEventCount = 0
    @State private var showResetConfirmation = false
    @State private var showClearAnalyticsConfirmation = false
    @State private var didResetProgress = false
    @State private var didClearAnalytics = false

    private let appInfo = AppInfo.current

    var body: some View {
        List {
            locationSection
            gameplaySection
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
            refreshAnalyticsCount()
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
            analyticsPreferenceStore: analyticsPreference
        )
    }
}
