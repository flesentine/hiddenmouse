import SwiftUI

struct DiscoveryThumbnailView: View {
    let imageName: String?
    var size: CGFloat = 56

    private let imageStore = BundledRevealImageStore()

    var body: some View {
        if let imageName,
           let image = imageStore.thumbnail(named: imageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
                .accessibilityHidden(true)
        }
    }
}
