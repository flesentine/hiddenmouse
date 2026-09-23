import Foundation

protocol AnalyticsRecording: AnyObject {
    func record(_ event: AnalyticsEventRecord)
    func events() -> [AnalyticsEventRecord]
    func clear()
}

final class UserDefaultsAnalyticsRecorder: AnalyticsRecording {
    static let defaultStorageKey = "parkhunt.analytics.events.v1"
    static let defaultMaximumEventCount = 500

    private let defaults: UserDefaults
    private let storageKey: String
    private let maximumEventCount: Int

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = defaultStorageKey,
        maximumEventCount: Int = defaultMaximumEventCount
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.maximumEventCount = max(maximumEventCount, 1)
    }

    func record(_ event: AnalyticsEventRecord) {
        var storedEvents = events()
        storedEvents.append(event)

        if storedEvents.count > maximumEventCount {
            storedEvents = Array(
                storedEvents.suffix(maximumEventCount)
            )
        }

        guard let data = try? JSONEncoder().encode(
            storedEvents
        ) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }

    func events() -> [AnalyticsEventRecord] {
        guard let data = defaults.data(forKey: storageKey),
              let events = try? JSONDecoder().decode(
                [AnalyticsEventRecord].self,
                from: data
              ) else {
            return []
        }

        return events
    }

    func clear() {
        defaults.removeObject(forKey: storageKey)
    }
}

final class MemoryAnalyticsRecorder: AnalyticsRecording {
    private var storedEvents: [AnalyticsEventRecord]
    private let maximumEventCount: Int

    init(
        events: [AnalyticsEventRecord] = [],
        maximumEventCount: Int = 500
    ) {
        let cappedMaximum = max(maximumEventCount, 1)
        self.maximumEventCount = cappedMaximum
        self.storedEvents = Array(
            events.suffix(cappedMaximum)
        )
    }

    func record(_ event: AnalyticsEventRecord) {
        storedEvents.append(event)

        if storedEvents.count > maximumEventCount {
            storedEvents = Array(
                storedEvents.suffix(maximumEventCount)
            )
        }
    }

    func events() -> [AnalyticsEventRecord] {
        storedEvents
    }

    func clear() {
        storedEvents = []
    }
}
