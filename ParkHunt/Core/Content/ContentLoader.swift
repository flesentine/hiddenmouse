import Foundation

final class ContentLoader {
    private let source: any ContentCatalogSource
    private let revealImageExists: (String) -> Bool

    private(set) var snapshot: ContentSnapshot?

    init(
        source: any ContentCatalogSource = BundledContentStore(),
        revealImageStore: BundledRevealImageStore = BundledRevealImageStore()
    ) {
        self.source = source
        self.revealImageExists = {
            revealImageStore.containsImage(named: $0)
        }
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

        let offlineIssues = OfflineReadinessValidator.validate(
            snapshot: loaded,
            imageExists: revealImageExists
        )

        guard offlineIssues.isEmpty else {
            throw ContentStoreError.offlineReadinessFailed(
                offlineIssues
            )
        }

        snapshot = loaded
        return loaded
    }

    func reset() {
        snapshot = nil
    }
}
