import SwiftUI

struct ManualLandSelectionView: View {
    let parkID: String
    let parkName: String
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let huntRouteDependencies: HuntRouteDependencies

    @State private var landOptions: [ManualLandOption] = []
    @State private var loadFailed = false
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView {
                    Label(
                        "Couldn’t Load Lands",
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
                ProgressView("Loading lands…")
            } else if landOptions.isEmpty {
                ContentUnavailableView(
                    "No Lands Available",
                    systemImage: "map",
                    description: Text("There are no browsable lands in this park yet.")
                )
            } else {
                List(landOptions) { land in
                    NavigationLink {
                        ManualLandBrowseView(
                            landID: land.id,
                            landName: land.name,
                            contentLoader: contentLoader,
                            progressStore: progressStore,
                            huntRouteDependencies: huntRouteDependencies
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(land.name)
                                .font(.headline)

                            Text(
                                ManualAreaPresentation.discoveryCountText(
                                    land.discoveryCount
                                )
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityIdentifier("manual.land.\(land.id)")
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(parkName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            load()
        }
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
            landOptions = ManualAreaPresentation.lands(
                inPark: parkID,
                snapshot: snapshot
            )
            loadFailed = false
        } catch {
            landOptions = []
            loadFailed = true
        }
    }
}
