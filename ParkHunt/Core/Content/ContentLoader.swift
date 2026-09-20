import Foundation

final class ContentLoader {
    private let source: any ContentCatalogSource
    private(set) var snapshot: ContentSnapshot?

    init(source: any ContentCatalogSource = BundledContentStore()) {
        self.source = source
    }

    @discardableResult
    func load() throws -> ContentSnapshot {
        if let snapshot {
            return snapshot
        }

        return try reload()
    }

    @discardableResult
    func reload() throws -> ContentSnapshot {
        let catalog = try source.loadCatalog()
        let loaded = ContentSnapshot(catalog: catalog)
        snapshot = loaded
        return loaded
    }

    func reset() {
        snapshot = nil
    }
}
