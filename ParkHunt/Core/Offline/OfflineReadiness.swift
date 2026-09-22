import Foundation

enum OfflineReadinessIssue: Equatable, Sendable {
    case missingRevealImage(
        discoveryID: String,
        imageName: String
    )
}

enum OfflineReadinessValidator {
    static func validate(
        snapshot: ContentSnapshot,
        imageExists: (String) -> Bool
    ) -> [OfflineReadinessIssue] {
        snapshot.discoveries.compactMap { discovery in
            guard let imageName = discovery.revealImageName,
                  !imageName.isEmpty else {
                return nil
            }

            guard !imageExists(imageName) else {
                return nil
            }

            return .missingRevealImage(
                discoveryID: discovery.id,
                imageName: imageName
            )
        }
    }
}
