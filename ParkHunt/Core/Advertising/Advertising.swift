import Foundation

enum AdPlacement: String, CaseIterable, Sendable {
    case home
    case collection
    case hunt
    case reveal
}

struct AdCreative: Equatable, Identifiable, Sendable {
    let id: String
    let sponsor: String
    let headline: String
    let body: String
}

protocol AdvertisingProviding: Sendable {
    func creative(for placement: AdPlacement) -> AdCreative?
}

struct NoopAdvertisingProvider: AdvertisingProviding {
    func creative(for placement: AdPlacement) -> AdCreative? {
        nil
    }
}

struct PreviewAdvertisingProvider: AdvertisingProviding {
    func creative(for placement: AdPlacement) -> AdCreative? {
        guard AdPolicy.isPassivePlacement(placement) else {
            return nil
        }

        return AdCreative(
            id: "preview-\(placement.rawValue)",
            sponsor: "Sample Sponsor",
            headline: "Preview sponsored placement",
            body: "Development-only creative used to verify spacing and premium suppression."
        )
    }
}

enum AdPolicy {
    static func isPassivePlacement(_ placement: AdPlacement) -> Bool {
        switch placement {
        case .home, .collection:
            true
        case .hunt, .reveal:
            false
        }
    }

    static func shouldShow(
        placement: AdPlacement,
        entitlement: PremiumEntitlement,
        provider: any AdvertisingProviding
    ) -> Bool {
        guard !entitlement.isPremium,
              isPassivePlacement(placement) else {
            return false
        }

        return provider.creative(for: placement) != nil
    }
}
