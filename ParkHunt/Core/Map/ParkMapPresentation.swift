import Foundation

struct ParkMapPoint: Equatable, Identifiable, Sendable {
    let discoveryID: String
    let title: String
    let landName: String
    let latitude: Double
    let longitude: Double
    let isFound: Bool

    var id: String { discoveryID }
}

struct ParkMapPresentation: Equatable, Sendable {
    let points: [ParkMapPoint]
    let mappedCount: Int
    let unmappedCount: Int

    static func make(
        snapshot: ContentSnapshot,
        progress: UserProgress
    ) -> ParkMapPresentation {
        var points: [ParkMapPoint] = []
        var unmappedCount = 0

        for discovery in snapshot.discoveries {
            guard let location = discovery.location else {
                unmappedCount += 1
                continue
            }

            points.append(
                ParkMapPoint(
                    discoveryID: discovery.id,
                    title: discovery.title,
                    landName: snapshot.land(id: discovery.landID)?.name
                        ?? discovery.landID,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    isFound: progress.progress(for: discovery.id).isFound
                )
            )
        }

        points.sort {
            if $0.landName == $1.landName {
                return $0.title.localizedCaseInsensitiveCompare($1.title)
                    == .orderedAscending
            }
            return $0.landName.localizedCaseInsensitiveCompare($1.landName)
                == .orderedAscending
        }

        return ParkMapPresentation(
            points: points,
            mappedCount: points.count,
            unmappedCount: unmappedCount
        )
    }
}
