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

struct ParkMapCluster: Equatable, Identifiable, Sendable {
    let latitude: Double
    let longitude: Double
    let points: [ParkMapPoint]

    var id: String {
        String(format: "%.6f,%.6f", latitude, longitude)
    }
}

struct ParkMapPresentation: Equatable, Sendable {
    let points: [ParkMapPoint]
    let clusters: [ParkMapCluster]
    let mappedCount: Int
    let unmappedCount: Int

    static func make(
        snapshot: ContentSnapshot,
        progress: UserProgress,
        parkID: String? = nil
    ) -> ParkMapPresentation {
        var points: [ParkMapPoint] = []
        var unmappedCount = 0

        for discovery in snapshot.discoveries
        where parkID == nil || discovery.parkID == parkID {
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

        let grouped = Dictionary(
            grouping: points,
            by: { CoordinateKey(latitude: $0.latitude, longitude: $0.longitude) }
        )

        let clusters = grouped.map { key, groupedPoints in
            ParkMapCluster(
                latitude: key.latitude,
                longitude: key.longitude,
                points: groupedPoints.sorted {
                    $0.title.localizedCaseInsensitiveCompare($1.title)
                        == .orderedAscending
                }
            )
        }
        .sorted {
            if $0.latitude == $1.latitude {
                return $0.longitude < $1.longitude
            }
            return $0.latitude < $1.latitude
        }

        return ParkMapPresentation(
            points: points,
            clusters: clusters,
            mappedCount: points.count,
            unmappedCount: unmappedCount
        )
    }
}

private struct CoordinateKey: Hashable {
    let latitude: Double
    let longitude: Double
}
