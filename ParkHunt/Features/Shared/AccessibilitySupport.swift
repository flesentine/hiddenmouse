import SwiftUI

struct AdaptiveMetadataView<Content: View>: View {
    let spacing: CGFloat
    private let content: () -> Content

    init(
        spacing: CGFloat = 12,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) {
                content()
            }

            VStack(alignment: .leading, spacing: 6) {
                content()
            }
        }
    }
}

enum ParkHuntAccessibility {
    static func nearbyResult(
        _ result: NearbyDiscoveryResult,
        areaName: String?
    ) -> String {
        var parts = [
            result.discovery.title,
            result.isFound ? "Found" : "Unfound",
            "\(result.discovery.difficulty.displayName) difficulty"
        ]

        if let areaName {
            parts.append(areaName)
        }

        if let distanceMeters = result.distanceMeters {
            parts.append(
                "about \(NextHuntRecommender.distanceText(distanceMeters)) away"
            )
        }

        return parts.joined(separator: ", ")
    }

    static func collectionItem(
        _ item: CollectionItem
    ) -> String {
        var parts = [
            item.discovery.title,
            collectionState(item.progressState),
            "\(item.discovery.difficulty.displayName) difficulty",
            item.landName
        ]

        if let areaName = item.areaName {
            parts.append(areaName)
        }

        if let foundAt = item.foundAt {
            parts.append(
                "found \(foundAt.formatted(date: .abbreviated, time: .omitted))"
            )
        } else if let lastViewedAt = item.lastViewedAt {
            parts.append(
                "last opened \(lastViewedAt.formatted(date: .abbreviated, time: .omitted))"
            )
        }

        return parts.joined(separator: ", ")
    }

    static func hint(
        title: String,
        position: String?,
        text: String
    ) -> String {
        [title, position, text]
            .compactMap { value in
                guard let value, !value.isEmpty else {
                    return nil
                }
                return value
            }
            .joined(separator: ". ")
    }

    static func progress(
        title: String,
        found: Int,
        total: Int
    ) -> String {
        "\(title), \(found) of \(total) found"
    }

    private static func collectionState(
        _ state: CollectionProgressState
    ) -> String {
        switch state {
        case .found:
            "Found"
        case .started:
            "Started"
        case .unstarted:
            "Unfound"
        }
    }
}

extension View {
    func parkHuntTapTarget() -> some View {
        frame(minHeight: 48)
            .contentShape(Rectangle())
    }
}
