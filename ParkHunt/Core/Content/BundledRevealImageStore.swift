import Foundation
import ImageIO
import UIKit

struct BundledRevealImageStore {
    static let thumbnailMaxPixelSize: CGFloat = 320
    static let revealMaxPixelSize: CGFloat = 1_600

    let bundle: Bundle

    init(
        bundle: Bundle = Bundle(for: ParkHuntBundleToken.self)
    ) {
        self.bundle = bundle
    }

    func containsImage(named name: String) -> Bool {
        resourceURL(named: name) != nil
    }

    @MainActor
    func thumbnail(named name: String) -> UIImage? {
        image(
            named: name,
            maxPixelSize: Self.thumbnailMaxPixelSize
        )
    }

    @MainActor
    func reveal(named name: String) -> UIImage? {
        image(
            named: name,
            maxPixelSize: Self.revealMaxPixelSize
        )
    }

    @MainActor
    private func image(
        named name: String,
        maxPixelSize: CGFloat
    ) -> UIImage? {
        let cacheKey = "\(name)|\(Int(maxPixelSize))" as NSString

        if let cached = BundledImageCache.shared.object(
            forKey: cacheKey
        ) {
            return cached
        }

        guard let url = resourceURL(named: name),
              let source = CGImageSourceCreateWithURL(
                url as CFURL,
                nil
              ) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize),
            kCGImageSourceShouldCacheImmediately: true
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            return nil
        }

        let image = UIImage(cgImage: cgImage)
        BundledImageCache.shared.setObject(
            image,
            forKey: cacheKey
        )
        return image
    }

    private func resourceURL(
        named name: String
    ) -> URL? {
        let fileURL = URL(fileURLWithPath: name)
        let fileExtension = fileURL.pathExtension

        guard !fileExtension.isEmpty else {
            return nil
        }

        let resourceName = fileURL
            .deletingPathExtension()
            .lastPathComponent

        return bundle.url(
            forResource: resourceName,
            withExtension: fileExtension
        ) ?? bundle.url(
            forResource: resourceName,
            withExtension: fileExtension,
            subdirectory: "Images"
        )
    }
}

@MainActor
private enum BundledImageCache {
    static let shared = NSCache<NSString, UIImage>()
}
