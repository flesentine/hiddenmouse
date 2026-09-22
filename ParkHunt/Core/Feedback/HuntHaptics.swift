import UIKit

enum HuntHapticEvent: Equatable, Sendable {
    case clueRevealed
    case detailedHelpRevealed
    case fullRevealOpened
    case discoveryFound
}

enum HuntHapticImpact: Equatable, Sendable {
    case light
    case medium
    case rigid
}

enum HuntHapticPattern: Equatable, Sendable {
    case impact(HuntHapticImpact)
    case success
}

enum HuntHapticPolicy {
    static func event(
        for action: HuntProgressionAction
    ) -> HuntHapticEvent {
        switch action {
        case let .revealHint(hint):
            switch hint.resolvedKind {
            case .clue:
                .clueRevealed
            case .detailed:
                .detailedHelpRevealed
            }

        case .revealLocation:
            .fullRevealOpened
        }
    }

    static func pattern(
        for event: HuntHapticEvent
    ) -> HuntHapticPattern {
        switch event {
        case .clueRevealed:
            .impact(.light)
        case .detailedHelpRevealed:
            .impact(.medium)
        case .fullRevealOpened:
            .impact(.rigid)
        case .discoveryFound:
            .success
        }
    }
}

enum HuntHaptics {
    @MainActor
    static func play(
        _ event: HuntHapticEvent
    ) {
        switch HuntHapticPolicy.pattern(for: event) {
        case let .impact(impact):
            let generator = UIImpactFeedbackGenerator(
                style: feedbackStyle(for: impact)
            )
            generator.prepare()
            generator.impactOccurred()

        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }

    private static func feedbackStyle(
        for impact: HuntHapticImpact
    ) -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch impact {
        case .light:
            .light
        case .medium:
            .medium
        case .rigid:
            .rigid
        }
    }
}
