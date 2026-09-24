import SwiftUI

struct RevealView: View {
    @Environment(\.dismiss) private var dismiss

    let discoveryID: String
    let contentLoader: ContentLoader

    private let imageStore = BundledRevealImageStore()

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
                        .accessibilityIdentifier("reveal.title")
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

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
        .accessibilityIdentifier("reveal.exact-location")
    }

    @ViewBuilder
    private func referencePhotoCard(
        _ presentation: RevealPresentation
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Reference Photo", systemImage: "photo")
                .font(.headline)

            if let imageName = presentation.referenceImageName,
               let image = imageStore.reveal(named: imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel(
                        "Reference photo for \(presentation.discovery.title). Visual aid for the exact location."
                    )
            } else {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(
                            presentation.referenceImageName == nil
                                ? "No reference photo yet"
                                : "Reference photo unavailable"
                        )
                        .font(.subheadline.weight(.semibold))

                        Text(
                            "The text reveal above is complete, so you can keep hunting without the photo."
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
        ContentUnavailableView {
            Label(
                "Reveal Unavailable",
                systemImage: "eye.slash"
            )
        } description: {
            Text(
                "This discovery is no longer available."
            )
        } actions: {
            Button("Back to Hunt") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
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
                load(reload: true)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func load(
        reload: Bool = false
    ) {
        loadState = .loading

        do {
            let snapshot = try reload
                ? contentLoader.reload()
                : contentLoader.load()
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
