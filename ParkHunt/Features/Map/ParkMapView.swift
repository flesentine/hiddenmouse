import MapKit
import SwiftUI

struct ParkMapView: View {
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring

    @State private var presentation: ParkMapPresentation?
    @State private var loadError: String?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedCluster: ParkMapCluster?

    var body: some View {
        Group {
            if let presentation {
                mapContent(presentation)
            } else if let loadError {
                ContentUnavailableView(
                    "Couldn’t Load Map",
                    systemImage: "map",
                    description: Text(loadError)
                )
            } else {
                ProgressView("Loading map…")
            }
        }
        .navigationTitle("Park Map")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            load()
        }
        .sheet(item: $selectedCluster) { cluster in
            NavigationStack {
                List(cluster.points) { point in
                    NavigationLink(value: point.discoveryID) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(point.title)
                                    .font(.headline)
                                Text(point.landName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if point.isFound {
                                Image(systemName: "checkmark.circle.fill")
                                    .accessibilityLabel("Found")
                            }
                        }
                    }
                }
                .navigationTitle("Hunts Here")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func mapContent(
        _ presentation: ParkMapPresentation
    ) -> some View {
        if presentation.points.isEmpty {
            ContentUnavailableView(
                "No Mapped Hunts Yet",
                systemImage: "map",
                description: Text(
                    "Hunts appear here after a field-tested map location has been added."
                )
            )
        } else {
            ZStack(alignment: .top) {
                Map(position: $cameraPosition) {
                    ForEach(presentation.clusters) { cluster in
                        Annotation(
                            cluster.points.count == 1
                                ? cluster.points[0].title
                                : "\(cluster.points.count) hunts",
                            coordinate: CLLocationCoordinate2D(
                                latitude: cluster.latitude,
                                longitude: cluster.longitude
                            ),
                            anchor: .bottom
                        ) {
                            if cluster.points.count == 1,
                               let point = cluster.points.first {
                                NavigationLink(value: point.discoveryID) {
                                    mapPin(
                                        foundCount: point.isFound ? 1 : 0,
                                        totalCount: 1
                                    )
                                }
                                .accessibilityLabel(
                                    point.isFound
                                        ? "\(point.title), found"
                                        : point.title
                                )
                                .accessibilityHint("Opens this hunt")
                            } else {
                                Button {
                                    selectedCluster = cluster
                                } label: {
                                    mapPin(
                                        foundCount: cluster.points.filter(\.isFound).count,
                                        totalCount: cluster.points.count
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(
                                    "\(cluster.points.count) hunts at this map location"
                                )
                                .accessibilityHint("Shows the hunts at this location")
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .accessibilityIdentifier("park-map")

                mapSummary(presentation)
                    .padding()
            }
        }
    }

    private func mapPin(
        foundCount: Int,
        totalCount: Int
    ) -> some View {
        ZStack {
            Image(
                systemName: foundCount == totalCount
                    ? "checkmark.circle.fill"
                    : "mappin.circle.fill"
            )
            .font(.title2)
            .padding(6)
            .background(.regularMaterial, in: Circle())

            if totalCount > 1 {
                Text("\(totalCount)")
                    .font(.caption2.bold())
                    .padding(4)
                    .background(.background, in: Circle())
                    .offset(x: 15, y: -15)
            }
        }
    }

    private func mapSummary(
        _ presentation: ParkMapPresentation
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(presentation.mappedCount) mapped hunt\(presentation.mappedCount == 1 ? "" : "s")")
                .font(.subheadline.weight(.semibold))

            if presentation.unmappedCount > 0 {
                Text(
                    "\(presentation.unmappedCount) field-test hunt\(presentation.unmappedCount == 1 ? "" : "s") awaiting a verified map location"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func load() {
        do {
            let snapshot = try contentLoader.load()
            let next = ParkMapPresentation.make(
                snapshot: snapshot,
                progress: progressStore.load()
            )
            presentation = next
            loadError = nil
            cameraPosition = initialCamera(for: next.points)
        } catch {
            presentation = nil
            loadError = "The bundled discovery catalog couldn’t be opened."
        }
    }

    private func initialCamera(
        for points: [ParkMapPoint]
    ) -> MapCameraPosition {
        guard let first = points.first else {
            return .automatic
        }

        var minLatitude = first.latitude
        var maxLatitude = first.latitude
        var minLongitude = first.longitude
        var maxLongitude = first.longitude

        for point in points.dropFirst() {
            minLatitude = min(minLatitude, point.latitude)
            maxLatitude = max(maxLatitude, point.latitude)
            minLongitude = min(minLongitude, point.longitude)
            maxLongitude = max(maxLongitude, point.longitude)
        }

        let latitudeDelta = max((maxLatitude - minLatitude) * 1.8, 0.003)
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.8, 0.003)

        return .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: (minLatitude + maxLatitude) / 2,
                    longitude: (minLongitude + maxLongitude) / 2
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: latitudeDelta,
                    longitudeDelta: longitudeDelta
                )
            )
        )
    }
}

#Preview {
    NavigationStack {
        ParkMapView(
            contentLoader: ContentLoader(),
            progressStore: MemoryUserProgressStore()
        )
    }
}
