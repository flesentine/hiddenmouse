import CoreLocation
import XCTest
@testable import ParkHunt

final class LocationServiceTests: XCTestCase {
    func testBatteryPolicyUsesCoarseHundredMeterAccuracy() {
        XCTAssertEqual(
            LocationService.requestedAccuracy,
            kCLLocationAccuracyHundredMeters
        )
    }

    func testBatteryPolicyBlocksDuplicateRequestWhileLocating() {
        XCTAssertFalse(
            LocationRequestPolicy.shouldRequest(
                state: .locating,
                authorization: .authorized
            )
        )
    }

    func testBatteryPolicyAllowsExplicitRetryAfterResult() {
        let fix = LocationFix(
            latitude: 33.8119,
            longitude: -117.9190,
            horizontalAccuracyMeters: 40,
            timestamp: Date()
        )

        XCTAssertTrue(
            LocationRequestPolicy.shouldRequest(
                state: .located(fix),
                authorization: .authorized
            )
        )
        XCTAssertTrue(
            LocationRequestPolicy.shouldRequest(
                state: .weakSignal(accuracyMeters: 500),
                authorization: .authorized
            )
        )
        XCTAssertTrue(
            LocationRequestPolicy.shouldRequest(
                state: .unavailable,
                authorization: .authorized
            )
        )
    }

    func testBatteryPolicyRejectsRequestsWithoutAuthorization() {
        for authorization: LocationAuthorizationState in [
            .notDetermined,
            .denied,
            .restricted,
        ] {
            XCTAssertFalse(
                LocationRequestPolicy.shouldRequest(
                    state: .idle,
                    authorization: authorization
                )
            )
        }
    }

    func testFreshAccurateFixIsUsable() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fix = LocationFix(
            latitude: 33.8119,
            longitude: -117.9190,
            horizontalAccuracyMeters: 30,
            timestamp: now
        )

        XCTAssertEqual(
            LocationService.quality(of: fix, now: now),
            .usable
        )
    }

    func testPoorAccuracyIsWeak() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fix = LocationFix(
            latitude: 33.8119,
            longitude: -117.9190,
            horizontalAccuracyMeters: 500,
            timestamp: now
        )

        XCTAssertEqual(
            LocationService.quality(of: fix, now: now),
            .weak
        )
    }

    func testOldFixIsStale() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fix = LocationFix(
            latitude: 33.8119,
            longitude: -117.9190,
            horizontalAccuracyMeters: 20,
            timestamp: now.addingTimeInterval(-120)
        )

        XCTAssertEqual(
            LocationService.quality(of: fix, now: now),
            .stale
        )
    }

    func testInvalidAccuracyIsRejected() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fix = LocationFix(
            latitude: 33.8119,
            longitude: -117.9190,
            horizontalAccuracyMeters: -1,
            timestamp: now
        )

        XCTAssertEqual(
            LocationService.quality(of: fix, now: now),
            .invalid
        )
    }
}
