import Foundation

protocol HapticPreferenceStoring: AnyObject {
    func load() -> Bool
    func save(_ isEnabled: Bool)
}

final class UserDefaultsHapticPreferenceStore: HapticPreferenceStoring {
    static let defaultStorageKey = "parkhunt.haptics-enabled.v1"

    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = defaultStorageKey
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    func load() -> Bool {
        guard defaults.object(forKey: storageKey) != nil else {
            return true
        }

        return defaults.bool(forKey: storageKey)
    }

    func save(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: storageKey)
    }
}

final class MemoryHapticPreferenceStore: HapticPreferenceStoring {
    private var isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func load() -> Bool {
        isEnabled
    }

    func save(_ isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}
