import Combine
@preconcurrency import CoreLocation
import Foundation

struct LocationFix: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let horizontalAccuracyMeters: Double
    let timestamp: Date
}

enum LocationFixQuality: Equatable, Sendable {
    case usable
    case weak
    case stale
    case invalid
}

enum LocationServiceState: Equatable, Sendable {
    case idle
    case locating
    case located(LocationFix)
    case weakSignal(accuracyMeters: Double)
    case unavailable
}

@MainActor
final class LocationService: NSObject, ObservableObject {
    nonisolated static let maximumUsefulAccuracyMeters = 250.0
    nonisolated static let maximumUsefulAgeSeconds = 60.0

    @Published private(set) var state: LocationServiceState = .idle

    private let manager: CLLocationManager

    override init() {
        let manager = CLLocationManager()
        self.manager = manager

        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func requestCurrentLocation() {
        let authorization = LocationPermissionController.authorizationState(
            for: manager.authorizationStatus
        )

        guard authorization.isAuthorized else {
            state = .unavailable
            return
        }

        state = .locating
        manager.requestLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()

        if state == .locating {
            state = .idle
        }
    }

    nonisolated static func quality(
        of fix: LocationFix,
        now: Date = Date()
    ) -> LocationFixQuality {
        guard fix.horizontalAccuracyMeters >= 0,
              (-90.0 ... 90.0).contains(fix.latitude),
              (-180.0 ... 180.0).contains(fix.longitude) else {
            return .invalid
        }

        if now.timeIntervalSince(fix.timestamp) > maximumUsefulAgeSeconds {
            return .stale
        }

        if fix.horizontalAccuracyMeters > maximumUsefulAccuracyMeters {
            return .weak
        }

        return .usable
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else {
            manager.stopUpdatingLocation()
            Task { @MainActor [weak self] in
                self?.state = .unavailable
            }
            return
        }

        let fix = LocationFix(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            horizontalAccuracyMeters: location.horizontalAccuracy,
            timestamp: location.timestamp
        )
        let quality = Self.quality(of: fix)

        manager.stopUpdatingLocation()

        Task { @MainActor [weak self] in
            guard let self else { return }

            switch quality {
            case .usable:
                state = .located(fix)
            case .weak:
                state = .weakSignal(
                    accuracyMeters: fix.horizontalAccuracyMeters
                )
            case .stale, .invalid:
                state = .unavailable
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        manager.stopUpdatingLocation()

        Task { @MainActor [weak self] in
            self?.state = .unavailable
        }
    }
}
