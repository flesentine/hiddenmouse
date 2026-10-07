import XCTest
@testable import ParkHunt

final class PremiumEntitlementTests: XCTestCase {
    func testFreeIsDefaultForEmptyUserDefaultsStore() {
        let suite = "premium-entitlement-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = UserDefaultsPremiumEntitlementStore(defaults: defaults)

        XCTAssertEqual(store.load(), .free)
    }

    func testEntitlementRoundTrips() {
        let store = MemoryPremiumEntitlementStore()

        store.save(.premium)

        XCTAssertEqual(store.load(), .premium)
    }

    func testExtendedTodayRoutesRequirePremium() {
        XCTAssertFalse(
            PremiumAccess.canUse(
                .extendedTodayRoutes,
                entitlement: .free
            )
        )
        XCTAssertTrue(
            PremiumAccess.canUse(
                .extendedTodayRoutes,
                entitlement: .premium
            )
        )
    }
}
