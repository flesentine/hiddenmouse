import Foundation

protocol UserProgressStoring: AnyObject {
    func load() -> UserProgress
    func save(_ progress: UserProgress)
}

final class UserDefaultsUserProgressStore: UserProgressStoring {
    static let defaultStorageKey = "parkhunt.user-progress.v1"

    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = defaultStorageKey
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    func load() -> UserProgress {
        guard let data = defaults.data(forKey: storageKey),
              let progress = try? JSONDecoder().decode(
                UserProgress.self,
                from: data
              ) else {
            return UserProgress()
        }

        return progress
    }

    func save(_ progress: UserProgress) {
        guard let data = try? JSONEncoder().encode(progress) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }
}

final class MemoryUserProgressStore: UserProgressStoring {
    private var progress: UserProgress

    init(progress: UserProgress = UserProgress()) {
        self.progress = progress
    }

    func load() -> UserProgress {
        progress
    }

    func save(_ progress: UserProgress) {
        self.progress = progress
    }
}
