import Foundation

struct ActiveHuntSession: Codable, Equatable, Sendable {
    let discoveryID: String
    var isRevealPresented: Bool

    init(
        discoveryID: String,
        isRevealPresented: Bool = false
    ) {
        self.discoveryID = discoveryID
        self.isRevealPresented = isRevealPresented
    }
}

protocol ActiveHuntStoring: AnyObject {
    func load() -> ActiveHuntSession?
    func save(_ session: ActiveHuntSession)
    func clear()
}

final class UserDefaultsActiveHuntStore: ActiveHuntStoring {
    static let defaultStorageKey = "parkhunt.active-hunt.v1"

    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = defaultStorageKey
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    func load() -> ActiveHuntSession? {
        guard let data = defaults.data(forKey: storageKey) else {
            return nil
        }

        return try? JSONDecoder().decode(
            ActiveHuntSession.self,
            from: data
        )
    }

    func save(_ session: ActiveHuntSession) {
        guard let data = try? JSONEncoder().encode(session) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }

    func clear() {
        defaults.removeObject(forKey: storageKey)
    }
}

final class MemoryActiveHuntStore: ActiveHuntStoring {
    private var session: ActiveHuntSession?

    init(session: ActiveHuntSession? = nil) {
        self.session = session
    }

    func load() -> ActiveHuntSession? {
        session
    }

    func save(_ session: ActiveHuntSession) {
        self.session = session
    }

    func clear() {
        session = nil
    }
}
