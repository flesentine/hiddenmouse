import Foundation

struct NearbyContext: Equatable, Sendable {
    let parkID: String
    let landID: String
    let landName: String
    let areaID: String?
    let areaName: String?
    let nearestDiscoveryID: String
    let distanceMeters: Double
}

enum NearbyContextResolver {
    static let maximumLandDistanceMeters = 1_500.0
    static let minimumAreaDistanceMeters = 250.0

    static func resolve(
        fix: LocationFix,
        snapshot: ContentSnapshot
    ) -> NearbyContext? {
        let candidates = snapshot.discoveries.compactMap { discovery -> Candidate? in
            guard let location = discovery.location,
                  let land = snapshot.land(id: discovery.landID) else {
                return nil
            }

            let distance = distanceMeters(
                fromLatitude: fix.latitude,
                longitude: fix.longitude,
                toLatitude: location.latitude,
                longitude: location.longitude
            )

            return Candidate(
                discovery: discovery,
                land: land,
                area: discovery.areaID.flatMap(snapshot.area(id:)),
                discoveryLocation: location,
                distanceMeters: distance
            )
        }

        guard let nearest = candidates.min(by: {
            if $0.distanceMeters == $1.distanceMeters {
                return $0.discovery.id < $1.discovery.id
            }
            return $0.distanceMeters < $1.distanceMeters
        }),
        nearest.distanceMeters <= maximumLandDistanceMeters else {
            return nil
        }

        let areaThreshold = max(
            minimumAreaDistanceMeters,
            nearest.discoveryLocation.radiusMeters * 2
        )
        let isCloseEnoughForArea = nearest.distanceMeters <= areaThreshold

        return NearbyContext(
            parkID: nearest.discovery.parkID,
            landID: nearest.land.id,
            landName: nearest.land.name,
            areaID: isCloseEnoughForArea ? nearest.area?.id : nil,
            areaName: isCloseEnoughForArea ? nearest.area?.name : nil,
            nearestDiscoveryID: nearest.discovery.id,
            distanceMeters: nearest.distanceMeters
        )
    }

    static func distanceMeters(
        fromLatitude latitude1: Double,
        longitude longitude1: Double,
        toLatitude latitude2: Double,
        longitude longitude2: Double
    ) -> Double {
        let earthRadiusMeters = 6_371_000.0

        let lat1 = latitude1 * .pi / 180
        let lat2 = latitude2 * .pi / 180
        let deltaLat = (latitude2 - latitude1) * .pi / 180
        let deltaLon = (longitude2 - longitude1) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2)
            * sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusMeters * c
    }

    private struct Candidate {
        let discovery: Discovery
        let land: Land
        let area: AttractionArea?
        let discoveryLocation: DiscoveryLocation
        let distanceMeters: Double
    }
}
