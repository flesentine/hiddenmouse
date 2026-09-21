import Foundation

protocol SpoilerPreferenceStoring: AnyObject {
    func load() -> SpoilerPreference
    func save(_ preference: SpoilerPreference)
}

final class UserDefaultsSpoilerPreferenceStore: SpoilerPreferenceStoring {
    static let defaultStorageKey = "parkhunt.spoiler-preference.v1"

    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = defaultStorageKey
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    func load() -> SpoilerPreference {
        guard let rawValue = defaults.string(forKey: storageKey),
              let preference = SpoilerPreference(rawValue: rawValue) else {
            return .normal
        }

        return preference
    }

    func save(_ preference: SpoilerPreference) {
        defaults.set(preference.rawValue, forKey: storageKey)
    }
}

final class MemorySpoilerPreferenceStore: SpoilerPreferenceStoring {
    private var preference: SpoilerPreference

    init(preference: SpoilerPreference = .normal) {
        self.preference = preference
    }

    func load() -> SpoilerPreference {
        preference
    }

    func save(_ preference: SpoilerPreference) {
        self.preference = preference
    }
}
