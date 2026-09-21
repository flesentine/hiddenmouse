import Foundation

enum NextHuntRecommender {
    static let maximumNearbyDistanceMeters = 1_500.0

    static func select(
        currentDiscovery: Discovery,
        snapshot: ContentSnapshot,
        progress: UserProgress
    ) -> NearbyDiscoveryResult? {
        let referenceFix = currentDiscovery.location.map {
            LocationFix(
                latitude: $0.latitude,
                longitude: $0.longitude,
                horizontalAccuracyMeters: 0,
                timestamp: Date()
            )
        }

        let context = NearbyDiscoveryContext(
            parkID: currentDiscovery.parkID,
            landID: currentDiscovery.landID,
            areaID: currentDiscovery.areaID,
            locationFix: referenceFix
        )

        let filters = NearbyDiscoveryFilters(
            scope: .park(currentDiscovery.parkID),
            found: .any,
            maximumDistanceMeters: referenceFix == nil
                ? nil
                : maximumNearbyDistanceMeters
        )

        return DiscoverySelector.select(
            snapshot: snapshot,
            context: context,
            filters: filters,
            progress: progress,
            request: DiscoverySelectionRequest(
                currentDiscoveryID: currentDiscovery.id
            )
        )
    }

    static func distanceText(_ meters: Double) -> String {
        if meters < 1_000 {
            let rounded = Int((meters / 10).rounded() * 10)
            return "\(max(rounded, 0)) m"
        }

        return String(format: "%.1f km", meters / 1_000)
    }
}
