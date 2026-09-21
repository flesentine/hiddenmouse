import Foundation

struct RevealPresentation: Equatable, Sendable {
    let discovery: Discovery
    let landName: String?
    let areaName: String?

    static func make(
        discoveryID: String,
        snapshot: ContentSnapshot
    ) -> RevealPresentation? {
        guard let discovery = snapshot.discovery(id: discoveryID) else {
            return nil
        }

        return RevealPresentation(
            discovery: discovery,
            landName: snapshot.land(id: discovery.landID)?.name,
            areaName: discovery.areaID
                .flatMap { snapshot.area(id: $0) }?
                .name
        )
    }

    var contextText: String? {
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

    var exactLocationText: String {
        discovery.revealDescription
    }

    var referenceImageName: String? {
        discovery.revealImageName
    }
}
