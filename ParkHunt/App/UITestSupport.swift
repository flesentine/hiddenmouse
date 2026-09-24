import Foundation

enum UITestSupport {
    private static var arguments: Set<String> {
        Set(ProcessInfo.processInfo.arguments)
    }

    private static var isEnabled: Bool {
        arguments.contains("--ui-testing")
    }

    static var forcedLocationAuthorizationState: LocationAuthorizationState? {
        guard isEnabled else {
            return nil
        }

        if arguments.contains("--ui-location-denied") {
            return .denied
        }

        return nil
    }

    static func prepareLaunch() {
        guard isEnabled,
              arguments.contains("--ui-reset-state"),
              let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return
        }

        UserDefaults.standard.removePersistentDomain(
            forName: bundleIdentifier
        )
        UserDefaults.standard.synchronize()
    }
}
