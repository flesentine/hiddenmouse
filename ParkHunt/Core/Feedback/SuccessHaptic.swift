import UIKit

@available(*, deprecated, message: "Use HuntHaptics.play(_:) instead.")
enum SuccessHaptic {
    @MainActor
    static func play() {
        HuntHaptics.play(.discoveryFound)
    }
}
