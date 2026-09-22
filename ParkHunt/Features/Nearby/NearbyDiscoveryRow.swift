import Foundation
import SwiftUI

struct NearbyDiscoveryRow: View {
    let result: NearbyDiscoveryResult
    let areaName: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            DiscoveryThumbnailView(
                imageName: result.discovery.thumbnailImageName
            )

            VStack(alignment: .leading, spacing: 7) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(result.discovery.title)
                            .font(.headline)

                        Spacer()

                        foundLabel
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(result.discovery.title)
                            .font(.headline)

                        foundLabel
                    }
                }

                AdaptiveMetadataView {
                    Label(
                        "\(result.discovery.difficulty.displayName) difficulty",
                        systemImage: "sparkles"
                    )

                    if let areaName {
                        Label(areaName, systemImage: "mappin")
                    }

                    if let distanceMeters = result.distanceMeters {
                        Label(
                            distanceText(distanceMeters),
                            systemImage: "location"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            ParkHuntAccessibility.nearbyResult(
                result,
                areaName: areaName
            )
        )
    }

    @ViewBuilder
    private var foundLabel: some View {
        if result.isFound {
            Label("Found", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func distanceText(_ meters: Double) -> String {
        if meters < 1_000 {
            let rounded = Int((meters / 10).rounded() * 10)
            return "\(max(rounded, 0)) m"
        }

        return String(format: "%.1f km", meters / 1_000)
    }
}
