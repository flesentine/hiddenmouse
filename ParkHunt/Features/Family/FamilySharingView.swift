import SwiftUI

struct FamilySharingView: View {
    let contentLoader: ContentLoader
    let service: any FamilySharingServicing

    @State private var availability: FamilySharingAvailability = .unavailable
    @State private var sharedProgress = FamilySharedProgress()
    @State private var totalDiscoveries = 0
    @State private var statusMessage: String?

    var body: some View {
        List {
            statusSection

            if case let .ready(group) = availability {
                membersSection(group)
                progressSection
                actionsSection
            }

            privacySection
        }
        .navigationTitle("Family")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            load()
        }
    }

    private var statusSection: some View {
        Section("Family Group") {
            HStack {
                Label("Status", systemImage: "person.3")

                Spacer()

                Text(statusText)
                    .foregroundStyle(.secondary)
            }

            if case let .ready(group) = availability {
                HStack {
                    Text("Group")
                    Spacer()
                    Text(group.name)
                        .foregroundStyle(.secondary)
                }
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func membersSection(
        _ group: FamilyGroup
    ) -> some View {
        Section("Members") {
            ForEach(group.members) { member in
                HStack {
                    Label(
                        member.displayName,
                        systemImage: member.isCurrentUser
                            ? "person.crop.circle.fill"
                            : "person.crop.circle"
                    )

                    if member.isCurrentUser {
                        Spacer()
                        Text("You")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var progressSection: some View {
        Section("Shared Progress") {
            HStack {
                Label("Family Finds", systemImage: "checkmark.circle")

                Spacer()

                Text(
                    "\(sharedProgress.foundDiscoveryIDs.count) / \(totalDiscoveries)"
                )
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }

            ProgressView(
                value: totalDiscoveries == 0
                    ? 0
                    : Double(sharedProgress.foundDiscoveryIDs.count)
                        / Double(totalDiscoveries)
            )
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                let result = service.publishFoundProgress()
                statusMessage = message(for: result)

                if result == .published {
                    refreshSharedProgress()
                }
            } label: {
                Label(
                    "Share My Found Hunts",
                    systemImage: "arrow.up.circle"
                )
            }

            Button {
                refreshSharedProgress()
            } label: {
                Label(
                    "Refresh Family Progress",
                    systemImage: "arrow.clockwise"
                )
            }
        } footer: {
            Text(
                "Sharing adds only the IDs of hunts you have marked Found. It does not upload clue history, reveals, timestamps, location, or local analytics."
            )
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Text(
                "Your personal progress remains separate. Family progress is an optional shared layer and never replaces or edits your private hunt history."
            )
            .foregroundStyle(.secondary)
        }
    }

    private var statusText: String {
        switch availability {
        case .unavailable:
            "Not Connected"
        case .notMember:
            "No Group"
        case .ready:
            "Connected"
        }
    }

    private func load() {
        availability = service.availability()

        do {
            totalDiscoveries = try contentLoader.load()
                .discoveries.count
        } catch {
            totalDiscoveries = 0
        }

        refreshSharedProgress()
    }

    private func refreshSharedProgress() {
        let result = service.loadSharedProgress()
        statusMessage = message(for: result)

        if case let .refreshed(progress) = result {
            sharedProgress = progress
        }
    }

    private func message(
        for result: FamilySharingResult
    ) -> String? {
        switch result {
        case .unavailable:
            "Family sharing provider is not available in this build."
        case .notMember:
            "Join or create a family group before sharing progress."
        case .published:
            "Your found hunts were added to family progress."
        case .refreshed:
            nil
        }
    }
}

#Preview {
    NavigationStack {
        FamilySharingView(
            contentLoader: ContentLoader(),
            service: FamilySharingService(
                personalProgressStore: MemoryUserProgressStore(),
                provider: MemoryFamilySharingProvider(
                    group: FamilyGroup(
                        id: "family",
                        name: "Park Crew",
                        members: [
                            FamilyMember(
                                id: "me",
                                displayName: "Chris",
                                isCurrentUser: true
                            ),
                            FamilyMember(
                                id: "other",
                                displayName: "Family Member",
                                isCurrentUser: false
                            )
                        ]
                    )
                )
            )
        )
    }
}
