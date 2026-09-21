import SwiftUI
import UIKit

struct RevealView: View {
    let discoveryID: String
    let contentLoader: ContentLoader

    @State private var presentation: RevealPresentation?
    @State private var loadState: LoadState = .loading

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                loadingView
            case .loaded:
                if let presentation {
                    revealContent(presentation)
                } else {
                    unavailableView
                }
            case .failed:
                failedView
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reveal")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            load()
        }
    }

    private func revealContent(
        _ presentation: RevealPresentation
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Full Reveal", systemImage: "eye.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(presentation.discovery.title)
                        .font(.largeTitle.bold())
                        .fixedSize(horizontal: false, vertical: true)

                    if let contextText = presentation.contextText {
                        Label(contextText, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)

                exactLocationCard(presentation)

                referencePhotoCard(presentation)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }

    private func exactLocationCard(
        _ presentation: RevealPresentation
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Exact Location", systemImage: "scope")
                .font(.headline)

            Text(presentation.exactLocationText)
                .font(.title3.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func referencePhotoCard(
        _ presentation: RevealPresentation
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Reference Photo", systemImage: "photo")
                .font(.headline)

            if let imageName = presentation.referenceImageName,
               let image = UIImage(named: imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel(
                        "Reference photo for \(presentation.discovery.title)"
                    )
            } else {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("No reference photo yet")
                            .font(.subheadline.weight(.semibold))

                        Text(
                            "The exact text reveal is still available. Original reference photos will be added with verified prototype content."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading reveal…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var unavailableView: some View {
        ContentUnavailableView(
            "Reveal Unavailable",
            systemImage: "eye.slash",
            description: Text(
                "This discovery is no longer available."
            )
        )
    }

    private var failedView: some View {
        ContentUnavailableView {
            Label(
                "Couldn’t Load Reveal",
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
            presentation = RevealPresentation.make(
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
        RevealView(
            discoveryID: "prototype-secret-001",
            contentLoader: ContentLoader()
        )
    }
}
