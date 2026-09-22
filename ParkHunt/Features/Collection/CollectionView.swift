import SwiftUI

struct CollectionView: View {
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring

    @State private var snapshot: ContentSnapshot?
    @State private var userProgress = UserProgress()
    @State private var filters = CollectionFilters()
    @State private var loadFailed = false
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Couldn’t Load Collection",
                    systemImage: "exclamationmark.triangle",
                    description: Text(
                        "Your offline discovery catalog couldn’t be opened."
                    )
                )
            } else if !hasLoaded {
                ProgressView("Loading collection…")
            } else if let collection {
                VStack(spacing: 0) {
                    filterBar(collection)

                    if collection.items.isEmpty {
                        emptyState
                    } else {
                        collectionList(collection)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Collection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            load()
        }
    }

    private var collection: CollectionSnapshot? {
        guard let snapshot else {
            return nil
        }

        return CollectionSnapshot.make(
            snapshot: snapshot,
            progress: userProgress,
            filters: filters
        )
    }

    private func filterBar(
        _ collection: CollectionSnapshot
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                statusMenu
                landMenu(collection)
                categoryMenu(collection)

                if !filters.isDefault {
                    Button {
                        filters = CollectionFilters()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
        .controlSize(.large)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.bar)
    }

    private var statusMenu: some View {
        Menu {
            ForEach(CollectionStatusFilter.allCases) { status in
                Button {
                    filters.status = status
                } label: {
                    if filters.status == status {
                        Label(
                            status.displayName,
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(status.displayName)
                    }
                }
            }
        } label: {
            Label(
                filters.status.displayName,
                systemImage: "line.3.horizontal.decrease.circle"
            )
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityLabel(
            "Status filter: \(filters.status.displayName)"
        )
    }

    private func landMenu(
        _ collection: CollectionSnapshot
    ) -> some View {
        Menu {
            Button {
                filters.landID = nil
            } label: {
                if filters.landID == nil {
                    Label("All Lands", systemImage: "checkmark")
                } else {
                    Text("All Lands")
                }
            }

            ForEach(collection.lands) { land in
                Button {
                    filters.landID = land.id
                } label: {
                    if filters.landID == land.id {
                        Label(land.name, systemImage: "checkmark")
                    } else {
                        Text(land.name)
                    }
                }
            }
        } label: {
            Label(
                selectedLandName(collection),
                systemImage: "map"
            )
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityLabel(
            "Land filter: \(selectedLandName(collection))"
        )
    }

    private func categoryMenu(
        _ collection: CollectionSnapshot
    ) -> some View {
        Menu {
            Button {
                filters.category = nil
            } label: {
                if filters.category == nil {
                    Label("All Categories", systemImage: "checkmark")
                } else {
                    Text("All Categories")
                }
            }

            ForEach(collection.categories, id: \.rawValue) { category in
                Button {
                    filters.category = category
                } label: {
                    if filters.category == category {
                        Label(
                            categoryName(category),
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(categoryName(category))
                    }
                }
            }
        } label: {
            Label(
                filters.category.map(categoryName) ?? "All Categories",
                systemImage: "square.grid.2x2"
            )
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityLabel(
            "Category filter: \(filters.category.map(categoryName) ?? "All Categories")"
        )
    }

    private func collectionList(
        _ collection: CollectionSnapshot
    ) -> some View {
        List(collection.items) { item in
            NavigationLink(value: item.discovery.id) {
                collectionRow(item)
            }
            .accessibilityHint(
                item.progressState == .found
                    ? "Reopens this completed hunt"
                    : "Opens this hunt"
            )
        }
        .listStyle(.insetGrouped)
    }

    private func collectionRow(
        _ item: CollectionItem
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            DiscoveryThumbnailView(
                imageName: item.discovery.thumbnailImageName
            )

            VStack(alignment: .leading, spacing: 7) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(item.discovery.title)
                            .font(.headline)

                        Spacer()

                        statusLabel(item)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.discovery.title)
                            .font(.headline)

                        statusLabel(item)
                    }
                }

                AdaptiveMetadataView {
                    Label(
                        "\(item.discovery.difficulty.displayName) difficulty",
                        systemImage: "sparkles"
                    )

                    Label(item.landName, systemImage: "map")

                    if let areaName = item.areaName {
                        Label(areaName, systemImage: "mappin")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let statusDateText = statusDateText(item) {
                    Text(statusDateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            ParkHuntAccessibility.collectionItem(item)
        )
    }

    @ViewBuilder
    private func statusLabel(
        _ item: CollectionItem
    ) -> some View {
        switch item.progressState {
        case .found:
            Label("Found", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        case .started:
            Label("Started", systemImage: "clock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        case .unstarted:
            Text("Unfound")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Matching Hunts",
            systemImage: "line.3.horizontal.decrease.circle",
            description: Text(
                filters.isDefault
                    ? "There are no available discoveries in the current catalog."
                    : "Try clearing or changing the collection filters."
            )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func selectedLandName(
        _ collection: CollectionSnapshot
    ) -> String {
        guard let landID = filters.landID else {
            return "All Lands"
        }

        return collection.lands.first {
            $0.id == landID
        }?.name ?? "Land"
    }

    private func statusDateText(
        _ item: CollectionItem
    ) -> String? {
        if let foundAt = item.foundAt {
            return "Found \(foundAt.formatted(date: .abbreviated, time: .omitted))"
        }

        if let lastViewedAt = item.lastViewedAt {
            return "Last opened \(lastViewedAt.formatted(date: .abbreviated, time: .omitted))"
        }

        return nil
    }

    private func categoryName(
        _ category: DiscoveryCategory
    ) -> String {
        switch category {
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

    private func load() {
        do {
            snapshot = try contentLoader.load()
            userProgress = progressStore.load()
            loadFailed = false
        } catch {
            snapshot = nil
            userProgress = UserProgress()
            loadFailed = true
        }

        hasLoaded = true
    }
}

#Preview {
    NavigationStack {
        CollectionView(
            contentLoader: ContentLoader(),
            progressStore: MemoryUserProgressStore()
        )
    }
}
