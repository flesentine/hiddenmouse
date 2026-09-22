import Foundation

enum OfflineReadinessIssue: Equatable, Sendable {
    case missingThumbnailImage(
        discoveryID: String,
        imageName: String
    )
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
        var issues: [OfflineReadinessIssue] = []

        for discovery in snapshot.discoveries {
            if let thumbnailName = discovery.thumbnailImageName,
               !thumbnailName.isEmpty,
               !imageExists(thumbnailName) {
                issues.append(
                    .missingThumbnailImage(
                        discoveryID: discovery.id,
                        imageName: thumbnailName
                    )
                )
            }

            if let revealName = discovery.revealImageName,
               !revealName.isEmpty,
               !imageExists(revealName) {
                issues.append(
                    .missingRevealImage(
                        discoveryID: discovery.id,
                        imageName: revealName
                    )
                )
            }
        }

        return issues
    }
}
