import SwiftUI
import UIKit

struct NearbyPermissionView: View {
    let contentLoader: ContentLoader

    @StateObject private var permission = LocationPermissionController()
    @StateObject private var locationService = LocationService()

    @Environment(\.openURL) private var openURL

    @State private var snapshot: ContentSnapshot?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero

                switch permission.state {
                case .notDetermined:
                    requestCard
                case .authorized:
                    authorizedContent
                case .denied:
                    deniedCard
                case .restricted:
                    restrictedCard
                }

                privacyNote
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Nearby")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            snapshot = try? contentLoader.load()

            if permission.state.isAuthorized,
               locationService.state == .idle {
                locate()
            }
        }
        .onChange(of: permission.state) { _, newState in
            if newState.isAuthorized {
                locate()
            }
        }
        .onDisappear {
            locationService.stop()
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "location.circle")
                .font(.system(size: 44, weight: .semibold))
                .accessibilityHidden(true)

            Text("Find discoveries around you")
                .font(.title2.bold())

            Text(
                "Use your location for a quick nearby check, or browse the park manually."
            )
            .font(.body)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var requestCard: some View {
        permissionCard {
            Text("Use your location?")
                .font(.headline)

            Text(
                "Location is optional. You can browse by park and land instead."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button {
                permission.requestWhenInUse()
            } label: {
                Label("Use My Location", systemImage: "location.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)

            browseByAreaButton
        }
    }

    @ViewBuilder
    private var authorizedContent: some View {
        switch locationService.state {
        case .idle, .locating:
            locatingCard
        case let .located(fix):
            locatedCard(fix: fix)
        case let .weakSignal(accuracyMeters):
            weakSignalCard(accuracyMeters: accuracyMeters)
        case .unavailable:
            unavailableCard
        }
    }

    private var locatingCard: some View {
        permissionCard {
            HStack(spacing: 12) {
                ProgressView()
                Text("Finding your area…")
                    .font(.headline)
            }

            Text(
                "Park Hunt is getting one foreground location fix, then it stops."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            browseByAreaButton
        }
    }

    private func locatedCard(fix: LocationFix) -> some View {
        let context = nearbyContext(for: fix)
        let results = nearbyResults(fix: fix, context: context)
        let suggested = DiscoverySelector.select(from: results)

        return VStack(alignment: .leading, spacing: 16) {
            permissionCard {
                Label("Location Found", systemImage: "location.fill")
                    .font(.headline)

                if let context {
                    Text(contextTitle(context))
                        .font(.title3.bold())

                    Text(contextDetail(context))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No known park area nearby")
                        .font(.title3.bold())

                    Text(
                        "Your location was found, but it isn’t close enough to an area in the current offline catalog."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Text(
                    "Accuracy about \(Int(fix.horizontalAccuracyMeters.rounded())) m"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if let suggested {
                    NavigationLink(value: suggested.discovery.id) {
                        Label(
                            "Start Suggested Hunt",
                            systemImage: "arrow.right.circle.fill"
                        )
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint(
                        "Starts the highest-ranked unfinished nearby hunt"
                    )
                }

                Button("Check Again") {
                    locate()
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .buttonStyle(.bordered)

                NavigationLink {
                    ManualAreaSelectionView(contentLoader: contentLoader)
                } label: {
                    Text(context == nil ? "Browse by Area" : "Browse Different Area")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
            }

            if !results.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Nearby hunts")
                        .font(.headline)

                    ForEach(results.prefix(5)) { result in
                        NavigationLink(value: result.discovery.id) {
                            NearbyDiscoveryRow(
                                result: result,
                                areaName: areaName(for: result.discovery)
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                .background,
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Starts this nearby hunt")
                    }
                }
            }
        }
    }

    private func weakSignalCard(
        accuracyMeters: Double
    ) -> some View {
        permissionCard {
            Label("Location Is Too Approximate", systemImage: "location.slash")
                .font(.headline)

            Text(
                "The current fix is only accurate to about \(Int(accuracyMeters.rounded())) m. Move into a more open area and try again."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button("Try Again") {
                locate()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.borderedProminent)

            browseByAreaButton
        }
    }

    private var unavailableCard: some View {
        permissionCard {
            Label("Couldn’t Find Your Location", systemImage: "location.slash")
                .font(.headline)

            Text(
                "GPS can be unreliable indoors or between large buildings. You can try again or browse manually."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button("Try Again") {
                locate()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.borderedProminent)

            browseByAreaButton
        }
    }

    private var deniedCard: some View {
        permissionCard {
            Label("Location Access Off", systemImage: "location.slash")
                .font(.headline)

            Text(
                "Browse by park and land without location, or enable access later in Settings."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            browseByAreaButton

            Button("Open Settings") {
                guard let url = URL(
                    string: UIApplication.openSettingsURLString
                ) else {
                    return
                }

                openURL(url)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.bordered)
        }
    }

    private var restrictedCard: some View {
        permissionCard {
            Label("Location Unavailable", systemImage: "location.slash")
                .font(.headline)

            Text(
                "Location access is restricted on this device, but manual browsing still works."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            browseByAreaButton
        }
    }

    private var browseByAreaButton: some View {
        NavigationLink {
            ManualAreaSelectionView(contentLoader: contentLoader)
        } label: {
            Label("Browse by Area", systemImage: "map")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
    }

    private var privacyNote: some View {
        Label {
            Text(
                "Park Hunt requests only When In Use access, takes a one-time fix for Nearby, and does not store location history."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func permissionCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private func locate() {
        locationService.requestCurrentLocation()
    }

    private func nearbyContext(for fix: LocationFix) -> NearbyContext? {
        guard let snapshot else {
            return nil
        }

        return NearbyContextResolver.resolve(
            fix: fix,
            snapshot: snapshot
        )
    }

    private func nearbyResults(
        fix: LocationFix,
        context: NearbyContext?
    ) -> [NearbyDiscoveryResult] {
        guard let snapshot,
              let context else {
            return []
        }

        return NearbyDiscoveryEngine.results(
            snapshot: snapshot,
            context: NearbyDiscoveryContext(
                parkID: context.parkID,
                landID: context.landID,
                areaID: context.areaID,
                locationFix: fix
            ),
            filters: NearbyDiscoveryFilters(
                scope: .park(context.parkID),
                found: .any,
                maximumDistanceMeters: NearbyContextResolver.maximumLandDistanceMeters
            )
        )
    }

    private func areaName(for discovery: Discovery) -> String? {
        guard let areaID = discovery.areaID else {
            return nil
        }

        return snapshot?.area(id: areaID)?.name
    }

    private func contextTitle(_ context: NearbyContext) -> String {
        context.areaName ?? context.landName
    }

    private func contextDetail(_ context: NearbyContext) -> String {
        if context.areaName != nil {
            return context.landName
        }

        return "Closest known land"
    }
}

#Preview {
    NavigationStack {
        NearbyPermissionView(contentLoader: ContentLoader())
    }
}
