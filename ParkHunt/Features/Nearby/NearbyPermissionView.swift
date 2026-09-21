import SwiftUI
import UIKit

struct NearbyPermissionView: View {
    @StateObject private var permission = LocationPermissionController()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero

                switch permission.state {
                case .notDetermined:
                    requestCard
                case .authorized:
                    authorizedCard
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

    private var authorizedCard: some View {
        permissionCard {
            Label("Location Access On", systemImage: "checkmark.circle.fill")
                .font(.headline)

            Text(
                "Park Hunt can use your location when you choose Nearby."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button("Continue") {
                dismiss()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.borderedProminent)
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
                "Park Hunt requests only When In Use access. The prototype does not store location history."
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
}

#Preview {
    NavigationStack {
        NearbyPermissionView()
    }
}
