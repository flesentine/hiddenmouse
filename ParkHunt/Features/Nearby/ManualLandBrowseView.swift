import SwiftUI

struct ManualLandBrowseView: View {
    @Environment(\.dismiss) private var dismiss

    let landID: String
    let landName: String
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring

    @State private var results: [NearbyDiscoveryResult] = []
    @State private var snapshot: ContentSnapshot?
    @State private var loadFailed = false
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView {
                    Label(
                        "Couldn’t Load Hunts",
                        systemImage: "exclamationmark.triangle"
                    )
                } description: {
                    Text("Your offline discovery catalog couldn’t be opened.")
                } actions: {
                    Button("Try Again") {
                        load(reload: true)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if !hasLoaded {
                ProgressView("Loading hunts…")
            } else if results.isEmpty {
                ContentUnavailableView {
                    Label(
                        "No Hunts Ready",
                        systemImage: "binoculars"
                    )
                } description: {
                    Text(
                        "There are no available discoveries in this land yet. Choose another land to keep browsing."
                    )
                } actions: {
                    Button("Choose Another Land") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    if availabilityState == .allComplete {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(
                                    "Land Complete",
                                    systemImage: "checkmark.circle.fill"
                                )
                                .font(.headline)

                                Text(
                                    "You’ve found every hunt in \(landName). Revisit a find below or choose another land."
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                                Button("Choose Another Land") {
                                    dismiss()
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 6)
                        }
                    }

                    if let suggested = suggestedResult {
                        Section {
                            NavigationLink(value: suggested.discovery.id) {
                                Label(
                                    "Start Suggested Hunt",
                                    systemImage: "arrow.right.circle.fill"
                                )
                                .font(.headline)
                            }
                            .accessibilityIdentifier("manual.start-suggested")
                            .accessibilityHint(
                                "Starts the highest-ranked unfinished hunt"
                            )
                        }
                    }

                    Section("All Hunts") {
                        ForEach(results) { result in
                            NavigationLink(value: result.discovery.id) {
                                NearbyDiscoveryRow(
                                    result: result,
                                    areaName: areaName(for: result.discovery)
                                )
                            }
                            .accessibilityHint("Starts this hunt")
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(landName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            load()
        }
    }

    private var suggestedResult: NearbyDiscoveryResult? {
        DiscoverySelector.select(from: results)
    }

    private var availabilityState: HuntAvailabilityState {
        HuntAvailabilityState.make(
            results: results
        )
    }

    private func load(
        reload: Bool = false
    ) {
        defer {
            hasLoaded = true
        }

        do {
            let loadedSnapshot = try reload
                ? contentLoader.reload()
                : contentLoader.load()
            snapshot = loadedSnapshot

            results = NearbyDiscoveryEngine.results(
                snapshot: loadedSnapshot,
                context: NearbyDiscoveryContext(landID: landID),
                filters: NearbyDiscoveryFilters(
                    scope: .land(landID),
                    found: .any
                ),
                progress: progressStore.load()
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
