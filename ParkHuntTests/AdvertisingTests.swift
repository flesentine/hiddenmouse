import XCTest
@testable import ParkHunt

final class AdvertisingTests: XCTestCase {
    func testPremiumSuppressesPassiveAds() {
        let provider = PreviewAdvertisingProvider()

        XCTAssertFalse(
            AdPolicy.shouldShow(
                placement: .home,
                entitlement: .premium,
                provider: provider
            )
        )
        XCTAssertFalse(
            AdPolicy.shouldShow(
                placement: .collection,
                entitlement: .premium,
                provider: provider
            )
        )
    }

    func testFreeCanShowPassiveAdsWhenProviderHasCreative() {
        let provider = PreviewAdvertisingProvider()

        XCTAssertTrue(
            AdPolicy.shouldShow(
                placement: .home,
                entitlement: .free,
                provider: provider
            )
        )
        XCTAssertTrue(
            AdPolicy.shouldShow(
                placement: .collection,
                entitlement: .free,
                provider: provider
            )
        )
    }

    func testActiveHuntAndRevealNeverAllowAds() {
        let provider = PreviewAdvertisingProvider()

        XCTAssertFalse(
            AdPolicy.shouldShow(
                placement: .hunt,
                entitlement: .free,
                provider: provider
            )
        )
        XCTAssertFalse(
            AdPolicy.shouldShow(
                placement: .reveal,
                entitlement: .free,
                provider: provider
            )
        )
    }

    func testNoopProviderProducesNoAd() {
        XCTAssertFalse(
            AdPolicy.shouldShow(
                placement: .home,
                entitlement: .free,
                provider: NoopAdvertisingProvider()
            )
        )
    }
}
