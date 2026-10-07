import Foundation

enum PremiumEntitlement: String, Codable, Equatable, Sendable {
    case free
    case premium

    var isPremium: Bool {
        self == .premium
    }
}

protocol PremiumEntitlementStoring: AnyObject {
    func load() -> PremiumEntitlement
    func save(_ entitlement: PremiumEntitlement)
}

final class UserDefaultsPremiumEntitlementStore: PremiumEntitlementStoring {
    static let storageKey = "parkhunt.premium-entitlement.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PremiumEntitlement {
        guard let rawValue = defaults.string(forKey: Self.storageKey),
              let entitlement = PremiumEntitlement(rawValue: rawValue) else {
            return .free
        }

        return entitlement
    }

    func save(_ entitlement: PremiumEntitlement) {
        defaults.set(entitlement.rawValue, forKey: Self.storageKey)
    }
}

final class MemoryPremiumEntitlementStore: PremiumEntitlementStoring {
    private var entitlement: PremiumEntitlement

    init(_ entitlement: PremiumEntitlement = .free) {
        self.entitlement = entitlement
    }

    func load() -> PremiumEntitlement {
        entitlement
    }

    func save(_ entitlement: PremiumEntitlement) {
        self.entitlement = entitlement
    }
}

enum PremiumFeature: String, CaseIterable, Sendable {
    case extendedTodayRoutes
}

enum PremiumAccess {
    static func canUse(
        _ feature: PremiumFeature,
        entitlement: PremiumEntitlement
    ) -> Bool {
        switch feature {
        case .extendedTodayRoutes:
            entitlement.isPremium
        }
    }
}
