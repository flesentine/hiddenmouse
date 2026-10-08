import SwiftUI

struct TodayHuntView: View {
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let premiumEntitlementStore: any PremiumEntitlementStoring

    @State private var snapshot: ContentSnapshot?
    @State private var progress = UserProgress()
    @State private var selectedLength: TodayRouteLength = .short
    @State private var entitlement: PremiumEntitlement = .free
    @State private var loadFailed = false
    @State private var selectedParkID = "disneyland"

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Couldn’t Build Today’s Hunt",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text(
                        "Your offline discovery catalog couldn’t be opened."
                    )
                )
            } else if let route {
                routeContent(route)
            } else {
                ProgressView("Building route…")
            }
        }
        .navigationTitle("Today’s Hunt")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            load()
        }
    }

    private var availableLengths: [TodayRouteLength] {
        if PremiumAccess.canUse(
            .extendedTodayRoutes,
            entitlement: entitlement
        ) {
            return TodayRouteLength.allCases
        }

        return [.short]
    }

    private var route: TodayRoute? {
        guard let snapshot else { return nil }

        return TodayRouteBuilder.build(
            snapshot: snapshot,
            progress: progress,
            length: selectedLength,
            parkID: selectedParkID
        )
    }

    private func routeContent(
        _ route: TodayRoute
    ) -> some View {
        List {
            Section {
                if let snapshot {
                    Picker("Park", selection: $selectedParkID) {
                        ForEach(ParkCatalog.options(in: snapshot)) { park in
                            Text(park.name).tag(park.id)
                        }
                    }
                }

                Picker("Route length", selection: $selectedLength) {
                    ForEach(availableLengths) { length in
                        Text(length.displayName).tag(length)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("today-hunt.length")

                if !PremiumAccess.canUse(
                    .extendedTodayRoutes,
                    entitlement: entitlement
                ) {
                    NavigationLink {
                        PremiumUpgradeView(
                            entitlementStore: premiumEntitlementStore
                        )
                    } label: {
                        Label(
                            "Unlock 5- and 8-hunt routes",
                            systemImage: "lock.fill"
                        )
                    }
                }
            } footer: {
                Text(
                    "Routes prefer unfinished hunts and keep you in one land when enough hunts are available."
                )
            }

            Section {
                if let focusLandName = route.focusLandName {
                    Label(
                        "Focused in \(focusLandName)",
                        systemImage: "map.fill"
                    )
                } else {
                    Label(
                        "Multi-land route",
                        systemImage: "point.topleft.down.curvedto.point.bottomright.up"
                    )
                }

                Text(
                    "\(route.items.count) of \(route.requestedCount) requested hunts available"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            if route.items.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Hunts Available",
                        systemImage: "binoculars",
                        description: Text(
                            "There are no huntable discoveries in the current catalog."
                        )
                    )
                }
            } else {
                Section("Route") {
                    ForEach(route.items) { item in
                        NavigationLink(value: item.discovery.id) {
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(item.sequence)")
                                    .font(.headline.monospacedDigit())
                                    .frame(width: 28, height: 28)
                                    .background(.thinMaterial, in: Circle())

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.discovery.title)
                                        .font(.headline)

                                    HStack(spacing: 10) {
                                        Label(item.landName, systemImage: "map")
                                        Label(
                                            item.discovery.difficulty.displayName,
                                            systemImage: "sparkles"
                                        )
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if item.isFound {
                                    Image(systemName: "checkmark.circle.fill")
                                        .accessibilityLabel("Found")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .accessibilityHint("Opens this hunt")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func load() {
        do {
            snapshot = try contentLoader.load()
            progress = progressStore.load()
            if let snapshot,
               !ParkCatalog.options(in: snapshot).contains(where: { $0.id == selectedParkID }) {
                selectedParkID = ParkCatalog.options(in: snapshot).first?.id ?? "disneyland"
            }
            entitlement = premiumEntitlementStore.load()

            if !availableLengths.contains(selectedLength) {
                selectedLength = .short
            }

            loadFailed = false
        } catch {
            snapshot = nil
            progress = UserProgress()
            loadFailed = true
        }
    }
}

#Preview {
    NavigationStack {
        TodayHuntView(
            contentLoader: ContentLoader(),
            progressStore: MemoryUserProgressStore(),
            premiumEntitlementStore: MemoryPremiumEntitlementStore(.premium)
        )
    }
}
