import SwiftUI

struct HuntView: View {
    let discoveryID: String
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let spoilerPreferenceStore: any SpoilerPreferenceStoring
    let hapticPreferenceStore: any HapticPreferenceStoring

    @Environment(\.dismiss) private var dismiss

    @State private var presentation: HuntPresentation?
    @State private var snapshot: ContentSnapshot?
    @State private var userProgress = UserProgress()
    @State private var spoilerPreference: SpoilerPreference = .normal
    @State private var loadState: LoadState = .loading
    @State private var isRevealPresented = false

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                loadingView
            case .loaded:
                if let presentation {
                    huntContent(presentation)
                } else {
                    unavailableView
                }
            case .failed:
                failedView
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Hunt")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isRevealPresented) {
            RevealView(
                discoveryID: discoveryID,
                contentLoader: contentLoader
            )
        }
        .task {
            load()
        }
    }

    private func huntContent(
        _ presentation: HuntPresentation
    ) -> some View {
        let progression = progressionState(for: presentation)
        let assistOptions = HuntAssistOptions.make(
            discovery: presentation.discovery,
            progression: progression,
            preference: spoilerPreference
        )

        return ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                huntHeader(presentation)

                if isFound(presentation) {
                    foundSuccessCard(presentation)
                }

                ForEach(
                    Array(progression.visibleHints.enumerated()),
                    id: \.element.id
                ) { index, hint in
                    hintCard(
                        hint,
                        visibleIndex: index,
                        totalHintCount: presentation.discovery.hints.count
                    )
                }

                if progression.isRevealVisible {
                    revealViewedCard
                } else if !isFound(presentation) {
                    instructionCard
                }

                Spacer(minLength: 140)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) {
            huntControls(
                progression: progression,
                assistOptions: assistOptions
            )
        }
    }

    private func huntHeader(
        _ presentation: HuntPresentation
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AdaptiveMetadataView {
                Label(
                    presentation.discovery.category.displayName,
                    systemImage: presentation.discovery.category.systemImageName
                )

                Label(
                    "\(presentation.discovery.difficulty.displayName) difficulty",
                    systemImage: "gauge.with.dots.needle.33percent"
                )
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            Text(presentation.discovery.title)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let locationText = presentation.locationText {
                Label(locationText, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Label(
                "\(spoilerPreference.displayName) help style",
                systemImage: spoilerPreference.systemImageName
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func hintCard(
        _ hint: Hint,
        visibleIndex: Int,
        totalHintCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Label(
                        hintTitle(hint, visibleIndex: visibleIndex),
                        systemImage: hint.resolvedKind == .detailed
                            ? "lifepreserver.fill"
                            : "lightbulb.fill"
                    )
                    .font(.headline)

                    Spacer()

                    if let position = hintPositionText(
                        hint,
                        visibleIndex: visibleIndex,
                        totalHintCount: totalHintCount
                    ) {
                        Text(position)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Label(
                        hintTitle(hint, visibleIndex: visibleIndex),
                        systemImage: hint.resolvedKind == .detailed
                            ? "lifepreserver.fill"
                            : "lightbulb.fill"
                    )
                    .font(.headline)

                    if let position = hintPositionText(
                        hint,
                        visibleIndex: visibleIndex,
                        totalHintCount: totalHintCount
                    ) {
                        Text(position)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(hint.text)
                .font(.title3.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            ParkHuntAccessibility.hint(
                title: hintTitle(hint, visibleIndex: visibleIndex),
                position: hintPositionText(
                    hint,
                    visibleIndex: visibleIndex,
                    totalHintCount: totalHintCount
                ),
                text: hint.text
            )
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }

    private var revealViewedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Reveal Viewed", systemImage: "eye.fill")
                .font(.headline)

            Text(
                "You’ve opened the full answer for this hunt. The spoiler stays on its own screen."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button {
                isRevealPresented = true
            } label: {
                Label("View Reveal Again", systemImage: "eye")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Opens the full reveal screen")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }

    private func foundSuccessCard(
        _ presentation: HuntPresentation
    ) -> some View {
        let recommendation = nextHuntRecommendation(
            for: presentation
        )

        return VStack(alignment: .leading, spacing: 14) {
            Label("Found It!", systemImage: "checkmark.seal.fill")
                .font(.title3.bold())

            Text(
                "Nice find. This discovery is saved to your progress."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let recommendation {
                Divider()

                Text("Up next")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(recommendation.discovery.title)
                    .font(.headline)

                nextHuntContext(recommendation)

                NavigationLink(value: recommendation.discovery.id) {
                    Label(
                        "Find Another",
                        systemImage: "arrow.right.circle.fill"
                    )
                    .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint(
                    "Starts the best unfinished hunt near this discovery"
                )
            } else {
                Divider()

                Label(
                    "Nearby set complete",
                    systemImage: "checkmark.circle"
                )
                .font(.subheadline.weight(.semibold))

                Text(
                    "There aren’t any unfinished hunts nearby in the current catalog."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }

    private var instructionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "eye")
                .font(.title3)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Look up from your phone")
                    .font(.subheadline.weight(.semibold))

                Text(
                    "Try the clue in the park first. Your Help Style controls how prominently Park Hunt offers the next level of assistance."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private func huntControls(
        progression: HuntProgressionState,
        assistOptions: HuntAssistOptions
    ) -> some View {
        VStack(spacing: 10) {
            if let presentation,
               !isFound(presentation) {
                Button {
                    markFound(presentation)
                } label: {
                    Label("I Found It", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint(
                    "Marks this discovery as found and saves it to your progress"
                )
            }

            if let primaryAction = assistOptions.primaryAction,
               !isCurrentDiscoveryFound {
                actionButton(
                    primaryAction,
                    prominent: true
                )
            }

            if let secondaryAction = assistOptions.secondaryAction,
               !isCurrentDiscoveryFound {
                actionButton(
                    secondaryAction,
                    prominent: false
                )
            }

            if !isCurrentDiscoveryFound,
               assistOptions.primaryAction == nil,
               assistOptions.secondaryAction == nil {
                Text(
                    progression.isRevealVisible
                        ? "You’ve revealed all available help for this hunt."
                        : "Keep exploring. Help is intentionally subtle in Explorer mode."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Button {
                dismiss()
            } label: {
                Label("Back to Hunts", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .accessibilityHint(
                "Leaves this hunt. Your clue progress is saved."
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }

    @ViewBuilder
    private func actionButton(
        _ action: HuntProgressionAction,
        prominent: Bool
    ) -> some View {
        if prominent {
            Button {
                perform(action)
            } label: {
                Label(
                    actionTitle(action),
                    systemImage: action.systemImageName
                )
                .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(
                accessibilityHint(for: action)
            )
        } else {
            Button {
                perform(action)
            } label: {
                Label(
                    actionTitle(action),
                    systemImage: action.systemImageName
                )
                .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .accessibilityHint(
                accessibilityHint(for: action)
            )
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading hunt…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var unavailableView: some View {
        ContentUnavailableView(
            "Hunt Unavailable",
            systemImage: "binoculars",
            description: Text(
                "This discovery is no longer available to hunt."
            )
        )
    }

    private var failedView: some View {
        ContentUnavailableView {
            Label(
                "Couldn’t Load Hunt",
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text("Your offline discovery catalog couldn’t be opened.")
        } actions: {
            Button("Try Again") {
                load()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var isCurrentDiscoveryFound: Bool {
        guard let presentation else {
            return false
        }

        return isFound(presentation)
    }

    private var detailedHintCount: Int {
        presentation?.discovery.hints.filter {
            $0.resolvedKind == .detailed
        }.count ?? 0
    }

    @ViewBuilder
    private func nextHuntContext(
        _ result: NearbyDiscoveryResult
    ) -> some View {
        AdaptiveMetadataView {
            Label(
                "\(result.discovery.difficulty.displayName) difficulty",
                systemImage: "sparkles"
            )

            if let areaID = result.discovery.areaID,
               let areaName = snapshot?.area(id: areaID)?.name {
                Label(areaName, systemImage: "mappin")
            }

            if let distanceMeters = result.distanceMeters {
                Label(
                    NextHuntRecommender.distanceText(distanceMeters),
                    systemImage: "location"
                )
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func nextHuntRecommendation(
        for presentation: HuntPresentation
    ) -> NearbyDiscoveryResult? {
        guard let snapshot else {
            return nil
        }

        return NextHuntRecommender.select(
            currentDiscovery: presentation.discovery,
            snapshot: snapshot,
            progress: userProgress
        )
    }

    private func isFound(
        _ presentation: HuntPresentation
    ) -> Bool {
        userProgress.progress(
            for: presentation.discovery.id
        ).isFound
    }

    private func markFound(
        _ presentation: HuntPresentation
    ) {
        guard !isFound(presentation) else {
            return
        }

        withAnimation {
            userProgress.recordFound(
                discoveryID: presentation.discovery.id
            )
            progressStore.save(userProgress)
        }

        if hapticPreferenceStore.load() {
            SuccessHaptic.play()
        }
    }

    private func progressionState(
        for presentation: HuntPresentation
    ) -> HuntProgressionState {
        HuntProgressionState.make(
            discovery: presentation.discovery,
            progress: userProgress.progress(
                for: presentation.discovery.id
            )
        )
    }

    private func hintPositionText(
        _ hint: Hint,
        visibleIndex: Int,
        totalHintCount: Int
    ) -> String? {
        guard hint.resolvedKind == .clue else {
            return nil
        }

        return "Clue \(visibleIndex + 1) of \(max(totalHintCount - detailedHintCount, 1))"
    }

    private func hintTitle(
        _ hint: Hint,
        visibleIndex: Int
    ) -> String {
        switch hint.resolvedKind {
        case .clue:
            visibleIndex == 0 ? "First Clue" : "Clue \(visibleIndex + 1)"
        case .detailed:
            "Detailed Hint"
        }
    }

    private func actionTitle(
        _ action: HuntProgressionAction
    ) -> String {
        if spoilerPreference == .explorer {
            return "Need Help"
        }

        return action.buttonTitle
    }

    private func accessibilityHint(
        for action: HuntProgressionAction
    ) -> String {
        switch action {
        case let .revealHint(hint):
            hint.resolvedKind == .detailed
                ? "Reveals a more specific hint"
                : "Reveals the next clue"
        case .revealLocation:
            "Opens the full reveal screen for this hunt"
        }
    }

    private func perform(
        _ action: HuntProgressionAction
    ) {
        guard let presentation else {
            return
        }

        withAnimation {
            switch action {
            case let .revealHint(hint):
                userProgress.recordHintViewed(
                    discoveryID: presentation.discovery.id,
                    order: hint.order
                )
            case .revealLocation:
                userProgress.recordRevealViewed(
                    discoveryID: presentation.discovery.id
                )
            }

            progressStore.save(userProgress)
        }

        if action == .revealLocation {
            isRevealPresented = true
        }
    }

    private func load() {
        loadState = .loading
        spoilerPreference = spoilerPreferenceStore.load()

        do {
            let loadedSnapshot = try contentLoader.load()
            guard let loadedPresentation = HuntPresentation.make(
                discoveryID: discoveryID,
                snapshot: loadedSnapshot
            ) else {
                snapshot = nil
                presentation = nil
                loadState = .loaded
                return
            }

            var loadedProgress = progressStore.load()

            if let firstHint = loadedPresentation.discovery.sortedHints.first {
                loadedProgress.recordHintViewed(
                    discoveryID: loadedPresentation.discovery.id,
                    order: firstHint.order
                )
                progressStore.save(loadedProgress)
            }

            userProgress = loadedProgress
            snapshot = loadedSnapshot
            presentation = loadedPresentation
            loadState = .loaded
        } catch {
            snapshot = nil
            presentation = nil
            loadState = .failed
        }
    }

    private enum LoadState {
        case loading
        case loaded
        case failed
    }
}

#Preview {
    NavigationStack {
        HuntView(
            discoveryID: "prototype-secret-001",
            contentLoader: ContentLoader(),
            progressStore: MemoryUserProgressStore(),
            spoilerPreferenceStore: MemorySpoilerPreferenceStore(),
            hapticPreferenceStore: MemoryHapticPreferenceStore()
        )
    }
}
