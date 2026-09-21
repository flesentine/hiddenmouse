import XCTest
@testable import ParkHunt

final class LocationServiceTests: XCTestCase {
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
