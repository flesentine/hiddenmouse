import Foundation

enum CompletedDiscoveryPolicy: Equatable, Sendable {
    case exclude
    case includeIfNeeded
}

struct DiscoverySelectionRequest: Equatable, Sendable {
    let currentDiscoveryID: String?
    let excludedDiscoveryIDs: Set<String>
    let completedPolicy: CompletedDiscoveryPolicy

    init(
        currentDiscoveryID: String? = nil,
        excludedDiscoveryIDs: Set<String> = [],
        completedPolicy: CompletedDiscoveryPolicy = .exclude
    ) {
        self.currentDiscoveryID = currentDiscoveryID
        self.excludedDiscoveryIDs = excludedDiscoveryIDs
        self.completedPolicy = completedPolicy
    }
}

enum DiscoverySelector {
    static func select(
        from rankedResults: [NearbyDiscoveryResult],
        request: DiscoverySelectionRequest = DiscoverySelectionRequest()
    ) -> NearbyDiscoveryResult? {
        let eligible = rankedResults.filter { result in
            result.discovery.id != request.currentDiscoveryID
                && !request.excludedDiscoveryIDs.contains(result.discovery.id)
        }

        if let unfound = eligible.first(where: { !$0.isFound }) {
            return unfound
        }

        guard request.completedPolicy == .includeIfNeeded else {
            return nil
        }

        return eligible.first
    }

    static func select(
        snapshot: ContentSnapshot,
        context: NearbyDiscoveryContext = NearbyDiscoveryContext(),
        filters: NearbyDiscoveryFilters = NearbyDiscoveryFilters(),
        progress: UserProgress = UserProgress(),
        request: DiscoverySelectionRequest = DiscoverySelectionRequest()
    ) -> NearbyDiscoveryResult? {
        let rankedResults = NearbyDiscoveryEngine.results(
            snapshot: snapshot,
            context: context,
            filters: filters,
            progress: progress
        )

        return select(
            from: rankedResults,
            request: request
        )
    }
}
