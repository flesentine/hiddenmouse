import SwiftUI

struct HuntView: View {
    let discoveryID: String
    let contentLoader: ContentLoader
    let progressStore: any UserProgressStoring
    let spoilerPreferenceStore: any SpoilerPreferenceStoring
    let hapticPreferenceStore: any HapticPreferenceStoring
    let activeHuntStore: any ActiveHuntStoring
    let analyticsRecorder: any AnalyticsRecording
    let launchContext: AnalyticsHuntLaunchContext = .standard

    @Environment(\.scenePhase) private var scenePhase

    @State private var presentation: HuntPresentation?
    @State private var snapshot: ContentSnapshot?
    @State private var userProgress = UserProgress()
    @State private var spoilerPreference: SpoilerPreference = .normal
    @State private var loadState: LoadState = .loading
    @State private var isRevealPresented = false
    @State private var didRecordHuntStart = false

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
        .onChange(of: isRevealPresented) { _, newValue in
            updateActiveSession(
                revealPresented: newValue
            )
        }
        .onDisappear {
            clearSessionForDeliberateExit()
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
        let recommendation = isFound(presentation)
            ? nextHuntRecommendation(for: presentation)
            : nil
        let thumbTrayState = HuntThumbTrayState.make(
            isFound: isFound(presentation),
            assistOptions: assistOptions,
            recommendation: recommendation
        )

        return ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                huntHeader(presentation)

                if isFound(presentation) {
                    foundSuccessCard(
                        recommendation: recommendation
                    )
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

                Spacer(minLength: 96)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) {
            huntControls(
                presentation: presentation,
                progression: progression,
                state: thumbTrayState
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
                updateActiveSession(
                    revealPresented: true
                )
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
        recommendation: NearbyDiscoveryResult?
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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

                Text("Find Another is ready below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

    @ViewBuilder
    private func huntControls(
        presentation: HuntPresentation,
        progression: HuntProgressionState,
        state: HuntThumbTrayState
    ) -> some View {
        switch state.mode {
        case let .active(mainAssist, alternateAssist):
            VStack(spacing: 10) {
                if let alternateAssist {
                    assistButton(alternateAssist)
                }

                if mainAssist == nil {
                    Text(
                        progression.isRevealVisible
                            ? "All available help has been revealed."
                            : "Keep looking around before asking for more help."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        if let mainAssist {
                            assistButton(mainAssist)
                        }

                        foundButton(presentation)
                    }

                    VStack(spacing: 10) {
                        if let mainAssist {
                            assistButton(mainAssist)
                        }

                        foundButton(presentation)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(.bar)

        case let .completed(nextDiscoveryID, nextDiscoveryTitle):
            if let nextDiscoveryID {
                VStack(spacing: 8) {
                    NavigationLink(value: nextDiscoveryID) {
                        Label(
                            "Find Another",
                            systemImage: "arrow.right.circle.fill"
                        )
                        .frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(
                        nextDiscoveryTitle.map {
                            "Find Another. Next hunt: \($0)"
                        } ?? "Find Another"
                    )
                    .accessibilityHint(
                        "Starts the best unfinished hunt near this discovery"
                    )
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            analyticsRecorder.record(
                                .findAnotherTapped(
                                    currentDiscovery: presentation.discovery,
                                    nextDiscoveryID: nextDiscoveryID
                                )
                            )
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(.bar)
            }
        }
    }

    private func foundButton(
        _ presentation: HuntPresentation
    ) -> some View {
        Button {
            markFound(presentation)
        } label: {
            Label("I Found It", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityHint(
            "Marks this discovery as found and saves it to your progress"
        )
    }

    private func assistButton(
        _ action: HuntProgressionAction
    ) -> some View {
        Button {
            perform(action)
        } label: {
            Label(
                actionTitle(action),
                systemImage: action.systemImageName
            )
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.bordered)
        .accessibilityHint(
            accessibilityHint(for: action)
        )
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

        analyticsRecorder.record(
            .discoveryFound(
                discovery: presentation.discovery
            )
        )
        clearActiveSessionIfMatching()
        playHapticIfEnabled(.discoveryFound)
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

        analyticsRecorder.record(
            .assistAction(
                action,
                discovery: presentation.discovery
            )
        )

        playHapticIfEnabled(
            HuntHapticPolicy.event(for: action)
        )

        if action == .revealLocation {
            updateActiveSession(
                revealPresented: true
            )
            isRevealPresented = true
        }
    }

    private func updateActiveSession(
        revealPresented: Bool
    ) {
        guard let presentation,
              !isFound(presentation) else {
            return
        }

        activeHuntStore.save(
            ActiveHuntSession(
                discoveryID: presentation.discovery.id,
                isRevealPresented: revealPresented
            )
        )
    }

    private func clearActiveSessionIfMatching() {
        guard activeHuntStore.load()?.discoveryID == discoveryID else {
            return
        }

        activeHuntStore.clear()
    }

    private func clearSessionForDeliberateExit() {
        guard scenePhase == .active,
              !isRevealPresented,
              activeHuntStore.load()?.discoveryID == discoveryID,
              let presentation,
              !isFound(presentation) else {
            return
        }

        analyticsRecorder.record(
            .huntExitedUnfinished(
                discovery: presentation.discovery
            )
        )
        activeHuntStore.clear()
    }

    private func playHapticIfEnabled(
        _ event: HuntHapticEvent
    ) {
        guard hapticPreferenceStore.load() else {
            return
        }

        HuntHaptics.play(event)
    }

    private func recordHuntStartIfNeeded(
        _ discovery: Discovery
    ) {
        guard !didRecordHuntStart else {
            return
        }

        didRecordHuntStart = true
        analyticsRecorder.record(
            .huntStarted(discovery: discovery)
        )
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
            let discoveryProgress = loadedProgress.progress(
                for: loadedPresentation.discovery.id
            )

            if discoveryProgress.highestHintOrderViewed == nil,
               !discoveryProgress.didRevealLocation,
               !discoveryProgress.isFound,
               let firstHint = loadedPresentation.discovery.sortedHints.first {
                loadedProgress.recordHintViewed(
                    discoveryID: loadedPresentation.discovery.id,
                    order: firstHint.order
                )
                progressStore.save(loadedProgress)
            }

            userProgress = loadedProgress
            snapshot = loadedSnapshot
            presentation = loadedPresentation

            if launchContext == .standard,
               !loadedProgress.progress(
                    for: loadedPresentation.discovery.id
               ).isFound {
                recordHuntStartIfNeeded(
                    loadedPresentation.discovery
                )
            }

            let restoredSession = activeHuntStore.load()
            let shouldRestoreReveal =
                restoredSession?.discoveryID == loadedPresentation.discovery.id
                && restoredSession?.isRevealPresented == true

            if loadedProgress.progress(
                for: loadedPresentation.discovery.id
            ).isFound {
                clearActiveSessionIfMatching()
            } else {
                activeHuntStore.save(
                    ActiveHuntSession(
                        discoveryID: loadedPresentation.discovery.id,
                        isRevealPresented: shouldRestoreReveal
                    )
                )
                isRevealPresented = shouldRestoreReveal
            }

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
            hapticPreferenceStore: MemoryHapticPreferenceStore(),
            activeHuntStore: MemoryActiveHuntStore(),
            analyticsRecorder: MemoryAnalyticsRecorder()
        )
    }
}
