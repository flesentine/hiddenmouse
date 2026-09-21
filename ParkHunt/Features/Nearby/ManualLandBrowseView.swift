import SwiftUI

struct ManualLandBrowseView: View {
    let landID: String
    let landName: String
    let contentLoader: ContentLoader

    @State private var discoveries: [Discovery] = []
    @State private var loadFailed = false
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Couldn’t Load Hunts",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Your offline discovery catalog couldn’t be opened.")
                )
            } else if !hasLoaded {
                ProgressView("Loading hunts…")
            } else if discoveries.isEmpty {
                ContentUnavailableView(
                    "No Hunts Ready",
                    systemImage: "binoculars",
                    description: Text("There are no available discoveries in this land yet.")
                )
            } else {
                List(discoveries) { discovery in
                    NavigationLink(value: discovery.id) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(discovery.title)
                                .font(.headline)

                            HStack(spacing: 12) {
                                Label(
                                    discovery.difficulty.displayName,
                                    systemImage: "sparkles"
                                )

                                if let areaName = areaName(for: discovery) {
                                    Label(areaName, systemImage: "mappin")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 5)
                    }
                    .accessibilityHint("Starts this hunt")
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(landName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            load()
        }
    }

    private func load() {
        defer {
            hasLoaded = true
        }

        do {
            let snapshot = try contentLoader.load()
            discoveries = snapshot.discoveries(inLand: landID)
            loadFailed = false
        } catch {
            discoveries = []
            loadFailed = true
        }
    }

    private func areaName(for discovery: Discovery) -> String? {
        guard let areaID = discovery.areaID,
              let snapshot = try? contentLoader.load() else {
            return nil
        }

        return snapshot.area(id: areaID)?.name
    }
}
