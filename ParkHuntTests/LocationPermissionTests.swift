import CoreLocation
import XCTest
@testable import ParkHunt

final class LocationPermissionTests: XCTestCase {
    func testNotDeterminedMapsWithoutAuthorization() {
        XCTAssertEqual(
            LocationPermissionController.authorizationState(
                for: .notDetermined
            ),
            .notDetermined
        )
    }

    func testWhenInUseMapsToAuthorized() {
        XCTAssertEqual(
            LocationPermissionController.authorizationState(
                for: .authorizedWhenInUse
            ),
            .authorized
        )
    }

    func testAlwaysMapsToAuthorized() {
        XCTAssertEqual(
            LocationPermissionController.authorizationState(
                for: .authorizedAlways
            ),
            .authorized
        )
    }

    func testDeniedAndRestrictedRemainDistinct() {
        XCTAssertEqual(
            LocationPermissionController.authorizationState(for: .denied),
            .denied
        )
        XCTAssertEqual(
            LocationPermissionController.authorizationState(for: .restricted),
            .restricted
        )
    }

    func testOnlyAuthorizedStateReportsAuthorized() {
        XCTAssertTrue(LocationAuthorizationState.authorized.isAuthorized)
        XCTAssertFalse(LocationAuthorizationState.notDetermined.isAuthorized)
        XCTAssertFalse(LocationAuthorizationState.denied.isAuthorized)
        XCTAssertFalse(LocationAuthorizationState.restricted.isAuthorized)
    }
}
