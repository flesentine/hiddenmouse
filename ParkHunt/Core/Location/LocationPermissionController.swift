import Combine
@preconcurrency import CoreLocation

enum LocationAuthorizationState: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted

    var isAuthorized: Bool {
        self == .authorized
    }
}

@MainActor
final class LocationPermissionController: NSObject, ObservableObject {
    @Published private(set) var state: LocationAuthorizationState

    private let manager: CLLocationManager

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.state = Self.authorizationState(for: manager.authorizationStatus)

        super.init()

        manager.delegate = self
    }

    func requestWhenInUse() {
        guard state == .notDetermined else {
            return
        }

        manager.requestWhenInUseAuthorization()
    }

    nonisolated static func authorizationState(
        for status: CLAuthorizationStatus
    ) -> LocationAuthorizationState {
        switch status {
        case .notDetermined:
            .notDetermined
        case .authorizedAlways, .authorizedWhenInUse:
            .authorized
        case .denied:
            .denied
        case .restricted:
            .restricted
        @unknown default:
            .restricted
        }
    }
}

extension LocationPermissionController: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        let nextState = Self.authorizationState(
            for: manager.authorizationStatus
        )

        Task { @MainActor [weak self] in
            self?.state = nextState
        }
    }
}
