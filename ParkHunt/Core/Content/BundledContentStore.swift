import Foundation

final class ParkHuntBundleToken {}

struct BundledContentStore {
    let bundle: Bundle
    let resourceName: String
    let resourceExtension: String

    init(
        bundle: Bundle = Bundle(for: ParkHuntBundleToken.self),
        resourceName: String = "content-catalog",
        resourceExtension: String = "json"
    ) {
        self.bundle = bundle
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
    }

    func loadCatalog() throws -> ContentCatalog {
        guard let url = bundle.url(
            forResource: resourceName,
            withExtension: resourceExtension
        ) else {
            throw ContentStoreError.resourceNotFound(
                name: resourceName,
                extension: resourceExtension
            )
        }

        return try FileContentStore(url: url).loadCatalog()
    }
}

struct FileContentStore {
    let url: URL

    func loadCatalog() throws -> ContentCatalog {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ContentStoreError.unreadableResource(
                path: url.path,
                reason: String(describing: error)
            )
        }

        return try ContentCatalogCodec.decode(data)
    }
}

enum ContentStoreError: Error, Equatable {
    case resourceNotFound(name: String, extension: String)
    case unreadableResource(path: String, reason: String)
    case decodingFailed(String)
    case validationFailed([ContentCatalogValidationIssue])
}
