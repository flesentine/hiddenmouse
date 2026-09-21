import Foundation

enum HuntProgressionAction: Equatable, Sendable {
    case revealHint(Hint)
    case revealLocation

    var buttonTitle: String {
        switch self {
        case let .revealHint(hint):
            switch hint.resolvedKind {
            case .clue:
                "Another Clue"
            case .detailed:
                "Give Me More Help"
            }
        case .revealLocation:
            "Show Me"
        }
    }

    var systemImageName: String {
        switch self {
        case let .revealHint(hint):
            switch hint.resolvedKind {
            case .clue:
                "lightbulb"
            case .detailed:
                "lifepreserver"
            }
        case .revealLocation:
            "eye.fill"
        }
    }
}

struct HuntProgressionState: Equatable, Sendable {
    let visibleHints: [Hint]
    let isRevealVisible: Bool
    let nextAction: HuntProgressionAction?

    static func make(
        discovery: Discovery,
        progress: DiscoveryProgress
    ) -> HuntProgressionState {
        let hints = discovery.sortedHints
        let firstOrder = hints.first?.order ?? 0
        let lastOrder = hints.last?.order ?? 0

        let highestVisibleOrder: Int
        if progress.didRevealLocation {
            highestVisibleOrder = lastOrder
        } else {
            highestVisibleOrder = max(
                progress.highestHintOrderViewed ?? firstOrder,
                firstOrder
            )
        }

        let visibleHints = hints.filter {
            $0.order <= highestVisibleOrder
        }

        let nextHint = hints.first {
            $0.order > highestVisibleOrder
        }

        let nextAction: HuntProgressionAction?
        if progress.didRevealLocation {
            nextAction = nil
        } else if let nextHint {
            nextAction = .revealHint(nextHint)
        } else {
            nextAction = .revealLocation
        }

        return HuntProgressionState(
            visibleHints: visibleHints,
            isRevealVisible: progress.didRevealLocation,
            nextAction: nextAction
        )
    }
}
