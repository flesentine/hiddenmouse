import SwiftUI
import UIKit

struct NearbyPermissionView: View {
    let contentLoader: ContentLoader

    @StateObject private var permission = LocationPermissionController()
    @StateObject private var locationService = LocationService()

    @Environment(\.dismiss) private var dismiss
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
                "Nearby can use your location while Park Hunt is open to help surface discoveries in the area you’re exploring."
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
                "Location is optional. You can keep using Park Hunt without sharing it."
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

            Button("Continue Without Location") {
                dismiss()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.bordered)
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
        }
    }

    private func locatedCard(fix: LocationFix) -> some View {
        let context = nearbyContext(for: fix)

        return permissionCard {
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

            Button("Check Again") {
                locate()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.bordered)
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

            Button("Continue Without Location") {
                dismiss()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.bordered)
        }
    }

    private var unavailableCard: some View {
        permissionCard {
            Label("Couldn’t Find Your Location", systemImage: "location.slash")
                .font(.headline)

            Text(
                "GPS can be unreliable indoors or between large buildings. You can try again or keep using Park Hunt without it."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button("Try Again") {
                locate()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.borderedProminent)

            Button("Continue Without Location") {
                dismiss()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.bordered)
        }
    }

    private var deniedCard: some View {
        permissionCard {
            Label("Location Access Off", systemImage: "location.slash")
                .font(.headline)

            Text(
                "You can keep browsing without location, or enable it later in Settings."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button("Open Settings") {
                guard let url = URL(
                    string: UIApplication.openSettingsURLString
                ) else {
                    return
                }

                openURL(url)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.borderedProminent)

            Button("Continue Without Location") {
                dismiss()
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
                "Location access is restricted on this device. You can still use Park Hunt without it."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button("Continue Without Location") {
                dismiss()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.borderedProminent)
        }
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
