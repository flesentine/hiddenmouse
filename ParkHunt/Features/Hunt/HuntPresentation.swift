import Foundation

struct HuntPresentation: Equatable, Sendable {
    let discovery: Discovery
    let landName: String?
    let areaName: String?

    static func make(
        discoveryID: String,
        snapshot: ContentSnapshot
    ) -> HuntPresentation? {
        guard let discovery = snapshot.discovery(id: discoveryID) else {
            return nil
        }

        let landName = snapshot.land(id: discovery.landID)?.name
        let areaName = discovery.areaID
            .flatMap { snapshot.area(id: $0) }?
            .name

        return HuntPresentation(
            discovery: discovery,
            landName: landName,
            areaName: areaName
        )
    }

    var locationText: String? {
        switch (landName, areaName) {
        case let (land?, area?):
            "\(land) · \(area)"
        case let (land?, nil):
            land
        case let (nil, area?):
            area
        case (nil, nil):
            nil
        }
    }
}

extension DiscoveryCategory {
    var displayName: String {
        switch self {
        case .hiddenMickey:
            "Hidden Mickey"
        case .hiddenCharacter:
            "Hidden Character"
        case .imagineeringDetail:
            "Imagineering Detail"
        case .movieReference:
            "Movie Reference"
        case .historicalDetail:
            "Historical Detail"
        case .easterEgg:
            "Easter Egg"
        case .secretFeature:
            "Secret Feature"
        }
    }

    var systemImageName: String {
        switch self {
        case .hiddenMickey, .hiddenCharacter:
            "sparkles"
        case .imagineeringDetail:
            "wrench.and.screwdriver"
        case .movieReference:
            "film"
        case .historicalDetail:
            "clock.arrow.circlepath"
        case .easterEgg:
            "eyes"
        case .secretFeature:
            "questionmark.circle"
        }
    }
}
