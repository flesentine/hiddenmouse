import SwiftUI

struct HomeView: View {
    let contentLoader: ContentLoader
    let spoilerPreferenceStore: any SpoilerPreferenceStoring

    @State private var presentation: HomePresentation?
    @State private var loadError: String?
    @State private var hasAttemptedLoad = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                nearbyCard

                if let presentation {
                    loadedContent(presentation)
                } else if let loadError {
                    errorContent(loadError)
                } else {
                    loadingContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Park Hunt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SpoilerSettingsView(
                        store: spoilerPreferenceStore
                    )
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Help Style")
            }
        }
        .task {
            guard !hasAttemptedLoad else { return }
            hasAttemptedLoad = true
            loadContent()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "scope")
                .font(.system(size: 40, weight: .semibold))
                .accessibilityHidden(true)

            Text("Discover what everyone else walks past.")
                .font(.title2.bold())

            Text("Pick a hunt, follow the clues, and keep your eyes on the park.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var nearbyCard: some View {
        NavigationLink {
            NearbyPermissionView(contentLoader: contentLoader)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "location.circle.fill")
                    .font(.title2)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Nearby")
                        .font(.headline)

                    Text("Find discoveries around where you are")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 52)
            .padding(18)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Choose whether to use your location for Nearby")
    }

    @ViewBuilder
    private func loadedContent(_ presentation: HomePresentation) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            areaCard(presentation)

            if let discoveryID = presentation.primaryDiscoveryID,
               let title = presentation.primaryDiscoveryTitle {
                featuredDiscovery(
                    id: discoveryID,
                    title: title,
                    difficulty: presentation.primaryDifficulty
                )
            } else {
                emptyContent
            }
        }
    }

    private func areaCard(_ presentation: HomePresentation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Prototype area", systemImage: "mappin.and.ellipse")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(presentation.landName)
                .font(.title3.bold())

            Text(presentation.discoveryCountText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private func featuredDiscovery(
        id: String,
        title: String,
        difficulty: Difficulty?
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ready to hunt")
                .font(.headline)

            Text(title)
                .font(.title3.weight(.semibold))

            if let difficulty {
                Label(
                    "\(difficulty.displayName) difficulty",
                    systemImage: "sparkles"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            NavigationLink(value: id) {
                HStack {
                    Text("Start Hunt")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .frame(minHeight: 44)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Opens this discovery")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var emptyContent: some View {
        ContentUnavailableView(
            "No Hunts Ready",
            systemImage: "binoculars",
            description: Text("There are no available discoveries in this area yet.")
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading discoveries…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .accessibilityElement(children: .combine)
    }

    private func errorContent(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Load Hunts", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                loadContent(reload: true)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func loadContent(reload: Bool = false) {
        do {
            let snapshot = try reload
                ? contentLoader.reload()
                : contentLoader.load()
            presentation = HomePresentation.make(from: snapshot)
            loadError = nil
        } catch {
            presentation = nil
            loadError = "Your offline discovery catalog couldn’t be opened."
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(
            contentLoader: ContentLoader(),
            spoilerPreferenceStore: MemorySpoilerPreferenceStore()
        )
    }
}
