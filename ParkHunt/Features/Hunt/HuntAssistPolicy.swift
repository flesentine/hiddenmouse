import Foundation

struct HuntAssistOptions: Equatable, Sendable {
    let primaryAction: HuntProgressionAction?
    let secondaryAction: HuntProgressionAction?
    let preference: SpoilerPreference

    static func make(
        discovery: Discovery,
        progression: HuntProgressionState,
        preference: SpoilerPreference
    ) -> HuntAssistOptions {
        guard !progression.isRevealVisible else {
            return HuntAssistOptions(
                primaryAction: nil,
                secondaryAction: nil,
                preference: preference
            )
        }

        switch preference {
        case .explorer:
            return HuntAssistOptions(
                primaryAction: nil,
                secondaryAction: progression.nextAction,
                preference: preference
            )

        case .normal:
            return HuntAssistOptions(
                primaryAction: progression.nextAction,
                secondaryAction: nil,
                preference: preference
            )

        case .helpMe:
            let visibleIDs = Set(progression.visibleHints.map(\.id))
            let detailedHint = discovery.sortedHints.first {
                $0.resolvedKind == .detailed
                    && !visibleIDs.contains($0.id)
            }
            let strongerAction = detailedHint.map(
                HuntProgressionAction.revealHint
            ) ?? progression.nextAction

            return HuntAssistOptions(
                primaryAction: strongerAction,
                secondaryAction: secondaryAction(
                    preferred: strongerAction,
                    standard: progression.nextAction
                ),
                preference: preference
            )

        case .showMe:
            let revealAction = HuntProgressionAction.revealLocation

            return HuntAssistOptions(
                primaryAction: revealAction,
                secondaryAction: secondaryAction(
                    preferred: revealAction,
                    standard: progression.nextAction
                ),
                preference: preference
            )
        }
    }

    private static func secondaryAction(
        preferred: HuntProgressionAction?,
        standard: HuntProgressionAction?
    ) -> HuntProgressionAction? {
        guard preferred != standard else {
            return nil
        }

        return standard
    }
}
