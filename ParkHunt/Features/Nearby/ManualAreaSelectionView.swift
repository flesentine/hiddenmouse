import SwiftUI

struct ManualAreaSelectionView: View {
    let contentLoader: ContentLoader

    @State private var parkOptions: [ManualParkOption] = []
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Couldn’t Load Areas",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Your offline park catalog couldn’t be opened.")
                )
            } else if parkOptions.isEmpty {
                ProgressView("Loading parks…")
            } else {
                List(parkOptions) { park in
                    NavigationLink {
                        ManualLandSelectionView(
                            parkID: park.id,
                            parkName: park.name,
                            contentLoader: contentLoader
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

    private func load() {
        do {
            let snapshot = try contentLoader.load()
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
        ManualAreaSelectionView(contentLoader: ContentLoader())
    }
}
