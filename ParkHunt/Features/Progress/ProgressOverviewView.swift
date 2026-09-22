import SwiftUI

struct ProgressOverviewView: View {
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring

    @State private var summary: ProgressSummary?
    @State private var loadFailed = false
    @State private var hasLoaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if loadFailed {
                    ContentUnavailableView(
                        "Couldn’t Load Progress",
                        systemImage: "exclamationmark.triangle",
                        description: Text(
                            "Your offline discovery catalog couldn’t be opened."
                        )
                    )
                } else if !hasLoaded {
                    ProgressView("Loading progress…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                } else if let summary {
                    overallCard(summary)

                    recentSection(summary)

                    progressSection(
                        title: "By Land",
                        systemImage: "map",
                        rows: summary.lands.map {
                            ProgressRowModel(
                                id: $0.id,
                                title: $0.name,
                                count: $0.count
                            )
                        }
                    )

                    progressSection(
                        title: "By Category",
                        systemImage: "square.grid.2x2",
                        rows: summary.categories.map {
                            ProgressRowModel(
                                id: $0.id,
                                title: categoryName($0.category),
                                count: $0.count
                            )
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            load()
        }
    }

    private func overallCard(
        _ summary: ProgressSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Overall")
                        .font(.headline)

                    Spacer()

                    Text(
                        "\(summary.overall.found) / \(summary.overall.total)"
                    )
                    .font(.title2.bold())
                    .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Overall")
                        .font(.headline)

                    Text(
                        "\(summary.overall.found) / \(summary.overall.total) found"
                    )
                    .font(.title3.bold())
                    .monospacedDigit()
                }
            }

            ProgressView(
                value: summary.overall.completionFraction
            )
            .accessibilityLabel("Overall progress")
            .accessibilityValue(
                "\(summary.overall.found) of \(summary.overall.total) found"
            )

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) {
                    stat(
                        value: summary.overall.found,
                        label: "Found"
                    )
                    stat(
                        value: summary.overall.started,
                        label: "Started"
                    )
                    stat(
                        value: summary.overall.remaining,
                        label: "Remaining"
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    stat(
                        value: summary.overall.found,
                        label: "Found"
                    )
                    stat(
                        value: summary.overall.started,
                        label: "Started"
                    )
                    stat(
                        value: summary.overall.remaining,
                        label: "Remaining"
                    )
                }
            }

            if let lastUpdatedAt = summary.lastUpdatedAt {
                Text(
                    "Updated \(lastUpdatedAt.formatted(date: .abbreviated, time: .shortened))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private func recentSection(
        _ summary: ProgressSummary
    ) -> some View {
        if summary.recentActivity != nil || summary.recentFound != nil {
            VStack(alignment: .leading, spacing: 12) {
                Label("Recent", systemImage: "clock")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                if let recentFound = summary.recentFound {
                    recentCard(
                        label: "Last Found",
                        item: recentFound,
                        date: recentFound.foundAt,
                        systemImage: "checkmark.circle.fill"
                    )
                }

                if let recentActivity = summary.recentActivity,
                   recentActivity.discoveryID != summary.recentFound?.discoveryID
                    || recentActivity.lastViewedAt != summary.recentFound?.foundAt {
                    recentCard(
                        label: "Last Activity",
                        item: recentActivity,
                        date: recentActivity.lastViewedAt,
                        systemImage: "eye"
                    )
                }
            }
        }
    }

    private func recentCard(
        label: String,
        item: RecentProgressDiscovery,
        date: Date?,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(label, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(item.title)
                .font(.headline)

            if let context = recentContext(item) {
                Text(context)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let date {
                Text(
                    date.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private func progressSection(
        title: String,
        systemImage: String,
        rows: [ProgressRowModel]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 8) {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Text(row.title)
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                            Text(
                                "\(row.count.found) / \(row.count.total)"
                            )
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .font(.subheadline.weight(.semibold))

                            Text(
                                "\(row.count.found) of \(row.count.total) found"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }

                    ProgressView(
                        value: row.count.completionFraction
                    )
                    .accessibilityLabel(row.title)
                    .accessibilityValue(
                        "\(row.count.found) of \(row.count.total) found"
                    )
                }
                .padding(16)
                .background(
                    .background,
                    in: RoundedRectangle(cornerRadius: 18)
                )
            }
        }
    }

    private func stat(
        value: Int,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.title3.bold())
                .monospacedDigit()

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func recentContext(
        _ item: RecentProgressDiscovery
    ) -> String? {
        switch (item.landName, item.areaName) {
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
            let snapshot = try contentLoader.load()
            summary = ProgressSummary.make(
                snapshot: snapshot,
                progress: progressStore.load()
            )
            loadFailed = false
        } catch {
            summary = nil
            loadFailed = true
        }

        hasLoaded = true
    }

    private struct ProgressRowModel: Identifiable {
        let id: String
        let title: String
        let count: ProgressCount
    }
}

#Preview {
    NavigationStack {
        ProgressOverviewView(
            contentLoader: ContentLoader(),
            progressStore: MemoryUserProgressStore()
        )
    }
}
