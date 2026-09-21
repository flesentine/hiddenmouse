import Foundation
import SwiftUI

struct NearbyDiscoveryRow: View {
    let result: NearbyDiscoveryResult
    let areaName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(result.discovery.title)
                    .font(.headline)

                Spacer()

                if result.isFound {
                    Label("Found", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Already found")
                }
            }

            HStack(spacing: 12) {
                Label(
                    result.discovery.difficulty.displayName,
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
        .padding(.vertical, 5)
    }

    private func distanceText(_ meters: Double) -> String {
        if meters < 1_000 {
            let rounded = Int((meters / 10).rounded() * 10)
            return "\(max(rounded, 0)) m"
        }

        return String(format: "%.1f km", meters / 1_000)
    }
}
