import SwiftUI

struct ManualLandBrowseView: View {
    let landID: String
    let landName: String
    let contentLoader: ContentLoader

    @State private var results: [NearbyDiscoveryResult] = []
    @State private var snapshot: ContentSnapshot?
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
            } else if results.isEmpty {
                ContentUnavailableView(
                    "No Hunts Ready",
                    systemImage: "binoculars",
                    description: Text("There are no available discoveries in this land yet.")
                )
            } else {
                List(results) { result in
                    NavigationLink(value: result.discovery.id) {
                        NearbyDiscoveryRow(
                            result: result,
                            areaName: areaName(for: result.discovery)
                        )
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
            let loadedSnapshot = try contentLoader.load()
            snapshot = loadedSnapshot

            results = NearbyDiscoveryEngine.results(
                snapshot: loadedSnapshot,
                context: NearbyDiscoveryContext(landID: landID),
                filters: NearbyDiscoveryFilters(
                    scope: .land(landID),
                    found: .any
                )
            )
            loadFailed = false
        } catch {
            snapshot = nil
            results = []
            loadFailed = true
        }
    }

    private func areaName(for discovery: Discovery) -> String? {
        guard let areaID = discovery.areaID else {
            return nil
        }

        return snapshot?.area(id: areaID)?.name
    }
}
