import Foundation

struct HuntThumbTrayState: Equatable, Sendable {
    enum Mode: Equatable, Sendable {
        case active(
            mainAssist: HuntProgressionAction?,
            alternateAssist: HuntProgressionAction?
        )
        case completed(
            nextDiscoveryID: String?,
            nextDiscoveryTitle: String?
        )
    }

    let mode: Mode

    static func make(
        isFound: Bool,
        assistOptions: HuntAssistOptions,
        recommendation: NearbyDiscoveryResult?
    ) -> HuntThumbTrayState {
        if isFound {
            return HuntThumbTrayState(
                mode: .completed(
                    nextDiscoveryID: recommendation?.discovery.id,
                    nextDiscoveryTitle: recommendation?.discovery.title
                )
            )
        }

        let mainAssist = assistOptions.primaryAction
            ?? assistOptions.secondaryAction
        let alternateAssist = assistOptions.primaryAction == nil
            ? nil
            : assistOptions.secondaryAction

        return HuntThumbTrayState(
            mode: .active(
                mainAssist: mainAssist,
                alternateAssist: alternateAssist
            )
        )
    }
}
