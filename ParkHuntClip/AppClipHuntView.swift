import SwiftUI

struct AppClipHuntView: View {
    let discoveryID: String
    let contentLoader: ContentLoader

    @State private var presentation: HuntPresentation?
    @State private var progress = UserProgress()
    @State private var failed = false

    var body: some View {
        Group {
            if let presentation {
                content(presentation)
            } else if failed {
                ContentUnavailableView(
                    "Hunt Unavailable",
                    systemImage: "binoculars"
                )
            } else {
                ProgressView("Loading hunt…")
            }
        }
        .navigationTitle("Park Hunt")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            load()
        }
    }

    private func content(
        _ presentation: HuntPresentation
    ) -> some View {
        let state = HuntProgressionState.make(
            discovery: presentation.discovery,
            progress: progress.progress(
                for: presentation.discovery.id
            )
        )

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(presentation.discovery.title)
                        .font(.largeTitle.bold())

                    if let location = presentation.locationText {
                        Label(
                            location,
                            systemImage: "mappin.and.ellipse"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                ForEach(state.visibleHints) { hint in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(
                            hint.resolvedKind == .detailed
                                ? "Detailed Hint"
                                : "Clue"
                        )
                        .font(.headline)

                        Text(hint.text)
                            .font(.title3)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(18)
                    .background(
                        .background,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                }

                if state.isRevealVisible {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(
                            "Reveal",
                            systemImage: "eye.fill"
                        )
                        .font(.headline)

                        Text(
                            presentation.discovery.revealDescription
                        )
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(18)
                    .background(
                        .background,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                }

                if progress.progress(
                    for: presentation.discovery.id
                ).isFound {
                    Label(
                        "Found!",
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.title3.bold())
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(18)
                    .background(
                        .background,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                }

                if let nextAction = state.nextAction,
                   !progress.progress(
                    for: presentation.discovery.id
                   ).isFound {
                    Button {
                        perform(
                            nextAction,
                            discoveryID: presentation.discovery.id
                        )
                    } label: {
                        Label(
                            nextAction.buttonTitle,
                            systemImage: nextAction.systemImageName
                        )
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 50
                        )
                    }
                    .buttonStyle(.bordered)
                }

                if !progress.progress(
                    for: presentation.discovery.id
                ).isFound {
                    Button {
                        markFound(
                            discoveryID: presentation.discovery.id
                        )
                    } label: {
                        Label(
                            "I Found It",
                            systemImage: "checkmark.circle.fill"
                        )
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 54
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func load() {
        do {
            let snapshot = try contentLoader.load()
            presentation = HuntPresentation.make(
                discoveryID: discoveryID,
                snapshot: snapshot
            )
            failed = presentation == nil
        } catch {
            failed = true
        }
    }

    private func perform(
        _ action: HuntProgressionAction,
        discoveryID: String
    ) {
        switch action {
        case let .revealHint(hint):
            progress.recordHintViewed(
                discoveryID: discoveryID,
                order: hint.order
            )
        case .revealLocation:
            progress.recordRevealViewed(
                discoveryID: discoveryID
            )
        }
    }

    private func markFound(
        discoveryID: String
    ) {
        progress.recordFound(
            discoveryID: discoveryID
        )
    }
}
