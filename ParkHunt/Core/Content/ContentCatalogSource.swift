import Foundation

protocol ContentCatalogSource {
    func loadCatalog() throws -> ContentCatalog
}

extension BundledContentStore: ContentCatalogSource {}
extension FileContentStore: ContentCatalogSource {}
