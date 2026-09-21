import SwiftUI

struct HuntView: View {
    let discoveryID: String
    let contentLoader: ContentLoader

    @Environment(\.dismiss) private var dismiss

    @State private var presentation: HuntPresentation?
    @State private var loadState: LoadState = .loading

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
        .task {
            load()
        }
    }

    private func huntContent(
        _ presentation: HuntPresentation
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                huntHeader(presentation)

                clueCard(presentation)

                instructionCard

                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) {
            huntControls
        }
    }

    private func huntHeader(
        _ presentation: HuntPresentation
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Label(
                    presentation.discovery.category.displayName,
                    systemImage: presentation.discovery.category.systemImageName
                )

                Label(
                    presentation.discovery.difficulty.displayName,
                    systemImage: "gauge.with.dots.needle.33percent"
                )
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            Text(presentation.discovery.title)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)

            if let locationText = presentation.locationText {
                Label(locationText, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func clueCard(
        _ presentation: HuntPresentation
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("First Clue", systemImage: "lightbulb.fill")
                    .font(.headline)

                Spacer()

                if let cluePositionText = presentation.cluePositionText {
                    Text(cluePositionText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if let firstHint = presentation.firstHint {
                Text(firstHint.text)
                    .font(.title3.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("First clue: \(firstHint.text)")
            } else {
                Text("This hunt does not have a clue available yet.")
                    .font(.body)
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
                    "Use the clue as a nudge, then explore the area around you. More help should only be needed if you get stuck."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private var huntControls: some View {
        VStack(spacing: 8) {
            Text("Keep exploring the area with the first clue.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                dismiss()
            } label: {
                Label("Back to Hunts", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Leaves this hunt and returns to the hunt list")
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
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

    private func load() {
        loadState = .loading

        do {
            let snapshot = try contentLoader.load()
            presentation = HuntPresentation.make(
                discoveryID: discoveryID,
                snapshot: snapshot
            )
            loadState = .loaded
        } catch {
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
            contentLoader: ContentLoader()
        )
    }
}
