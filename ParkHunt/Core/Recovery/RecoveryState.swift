import Foundation

enum CatalogRecoveryKind: Equatable, Sendable {
    case missingContent
    case invalidContent
    case missingAssets
    case unavailable
}

struct CatalogRecoveryPresentation: Equatable, Sendable {
    let kind: CatalogRecoveryKind
    let title: String
    let message: String

    static func make(
        error: Error
    ) -> CatalogRecoveryPresentation {
        guard let contentError = error as? ContentStoreError else {
            return CatalogRecoveryPresentation(
                kind: .unavailable,
                title: "Couldn’t Load Offline Content",
                message: "Park Hunt couldn’t open its offline content. Try again."
            )
        }

        switch contentError {
        case .resourceNotFound, .unreadableResource:
            return CatalogRecoveryPresentation(
                kind: .missingContent,
                title: "Offline Content Missing",
                message: "This build is missing required offline content. Try again; if it continues, the app content needs to be repaired."
            )

        case .decodingFailed, .validationFailed:
            return CatalogRecoveryPresentation(
                kind: .invalidContent,
                title: "Offline Content Invalid",
                message: "The packaged hunt data couldn’t be validated. Try again; if it continues, this build needs corrected content."
            )

        case .offlineReadinessFailed:
            return CatalogRecoveryPresentation(
                kind: .missingAssets,
                title: "Offline Content Incomplete",
                message: "One or more required offline assets are missing. Try again; if it continues, this build needs corrected content."
            )
        }
    }
}

enum HuntAvailabilityState: Equatable, Sendable {
    case available
    case noneAvailable
    case allComplete

    static func make(
        results: [NearbyDiscoveryResult]
    ) -> HuntAvailabilityState {
        guard !results.isEmpty else {
            return .noneAvailable
        }

        if results.allSatisfy(\.isFound) {
            return .allComplete
        }

        return .available
    }
}
