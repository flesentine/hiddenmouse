import UIKit

enum SuccessHaptic {
    @MainActor
    static func play() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
