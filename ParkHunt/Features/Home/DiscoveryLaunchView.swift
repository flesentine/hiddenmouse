import SwiftUI

struct DiscoveryLaunchView: View {
    let discoveryID: String
    let contentLoader: ContentLoader

    @State private var discovery: Discovery?
    @State private var landName: String?
    @State private var areaName: String?

    var body: some View {
        Group {
            if let discovery {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Label(
                            discovery.difficulty.displayName,
                            systemImage: "sparkles"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                        Text(discovery.title)
                            .font(.largeTitle.bold())

                        if let locationText {
                            Label(locationText, systemImage: "mappin")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        Text("Your hunt starts here.")
                            .font(.title3.bold())

                        Text("The full progressive clue experience will build on this handoff screen.")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        if let firstHint = discovery.sortedHints.first {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("First clue")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Text(firstHint.text)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(.background, in: RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                ContentUnavailableView(
                    "Discovery Unavailable",
                    systemImage: "binoculars",
                    description: Text("This discovery is no longer available to hunt.")
                )
            }
        }
        .navigationTitle("Hunt")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadDiscovery()
        }
    }

    private var locationText: String? {
        switch (landName, areaName) {
        case let (land?, area?):
            "\(land) · \(area)"
        case let (land?, nil):
            land
        case let (nil, area?):
            area
        case (nil, nil):
            nil
        }
    }

    private func loadDiscovery() {
        guard let snapshot = try? contentLoader.load(),
              let loadedDiscovery = snapshot.discovery(id: discoveryID) else {
            return
        }

        discovery = loadedDiscovery
        landName = snapshot.land(id: loadedDiscovery.landID)?.name

        if let areaID = loadedDiscovery.areaID {
            areaName = snapshot.area(id: areaID)?.name
        }
    }
}
