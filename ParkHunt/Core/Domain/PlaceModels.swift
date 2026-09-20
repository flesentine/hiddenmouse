import Foundation

struct Land: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let parkID: String
    let name: String
    let sortOrder: Int
}

struct AttractionArea: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let landID: String
    let name: String
    let kind: AttractionAreaKind
    let sortOrder: Int
}

enum AttractionAreaKind: String, Codable, CaseIterable, Hashable, Sendable {
    case attraction
    case area
}
