import Foundation

struct ContentCatalog: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let lands: [Land]
    let areas: [AttractionArea]
    let discoveries: [Discovery]
}

enum ContentCatalogCodec {
    static func decode(_ data: Data) throws -> ContentCatalog {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let catalog: ContentCatalog
        do {
            catalog = try decoder.decode(ContentCatalog.self, from: data)
        } catch {
            throw ContentStoreError.decodingFailed(String(describing: error))
        }

        let issues = ContentCatalogValidator.validate(catalog)
        guard issues.isEmpty else {
            throw ContentStoreError.validationFailed(issues)
        }

        return catalog
    }
}
