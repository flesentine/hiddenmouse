import SwiftUI

struct ManualAreaSelectionView: View {
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let huntRouteDependencies: HuntRouteDependencies

    @State private var parkOptions: [ManualParkOption] = []
    @State private var loadFailed = false
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView {
                    Label(
                        "Couldn’t Load Areas",
                        systemImage: "exclamationmark.triangle"
                    )
                } description: {
                    Text("Your offline park catalog couldn’t be opened.")
                } actions: {
                    Button("Try Again") {
                        load(reload: true)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if !hasLoaded {
                ProgressView("Loading parks…")
            } else if parkOptions.isEmpty {
                ContentUnavailableView(
                    "No Parks Available",
                    systemImage: "map",
                    description: Text("There are no browsable parks in the current catalog yet.")
                )
            } else {
                List(parkOptions) { park in
                    NavigationLink {
                        ManualLandSelectionView(
                            parkID: park.id,
                            parkName: park.name,
                            contentLoader: contentLoader,
                            progressStore: progressStore,
                            huntRouteDependencies: huntRouteDependencies
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(park.name)
                                .font(.headline)

                            Text(parkSummary(park))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityIdentifier("manual.park.\(park.id)")
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Choose Park")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            load()
        }
    }

    private func parkSummary(_ park: ManualParkOption) -> String {
        let landWord = park.landCount == 1 ? "land" : "lands"
        return "\(park.landCount) \(landWord) · \(ManualAreaPresentation.discoveryCountText(park.discoveryCount))"
    }

    private func load(
        reload: Bool = false
    ) {
        defer {
            hasLoaded = true
        }

        do {
            let snapshot = try reload
                ? contentLoader.reload()
                : contentLoader.load()
            parkOptions = ManualAreaPresentation.parks(from: snapshot)
            loadFailed = false
        } catch {
            parkOptions = []
            loadFailed = true
        }
    }
}

#Preview {
    NavigationStack {
        ManualAreaSelectionView(
            contentLoader: ContentLoader(),
            progressStore: MemoryUserProgressStore(),
            huntRouteDependencies: .preview
        )
    }
}
