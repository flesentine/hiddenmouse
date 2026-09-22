import SwiftUI
import UIKit

struct SettingsView: View {
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let spoilerPreferenceStore: any SpoilerPreferenceStoring
    let hapticPreferenceStore: any HapticPreferenceStoring

    @StateObject private var locationPermission = LocationPermissionController()
    @Environment(\.openURL) private var openURL

    @State private var helpStyle: SpoilerPreference = .normal
    @State private var hapticsEnabled = true
    @State private var showResetConfirmation = false
    @State private var didResetProgress = false

    private let appInfo = AppInfo.current

    var body: some View {
        List {
            locationSection
            gameplaySection
            dataSection
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            helpStyle = spoilerPreferenceStore.load()
            hapticsEnabled = hapticPreferenceStore.load()
        }
        .alert(
            "Reset Hunt Progress?",
            isPresented: $showResetConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Progress", role: .destructive) {
                progressStore.reset()
                didResetProgress = true
            }
        } message: {
            Text(
                "This clears found hunts, clue progress, reveal history, and progress timestamps on this device. Help Style and haptics will not change."
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
                        progressStore: progressStore
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
                "Park Hunt asks for When In Use access only from Nearby. Manual park and land browsing works without location."
            )
        }
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
                "Reset affects only hunt history on this device."
            )
        }
    }

    private var aboutSection: some View {
        Section("About") {
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
    NavigationStack {
        SettingsView(
            contentLoader: ContentLoader(),
            progressStore: MemoryUserProgressStore(),
            spoilerPreferenceStore: MemorySpoilerPreferenceStore(),
            hapticPreferenceStore: MemoryHapticPreferenceStore()
        )
    }
}
