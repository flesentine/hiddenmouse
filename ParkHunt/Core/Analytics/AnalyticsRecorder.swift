import Foundation

protocol AnalyticsRecording: AnyObject {
    func record(_ event: AnalyticsEventRecord)
    func events() -> [AnalyticsEventRecord]
    func clear()
}

final class UserDefaultsAnalyticsRecorder: AnalyticsRecording {
    static let defaultStorageKey = "parkhunt.analytics.events.v1"
    static let defaultMaximumEventCount = 500
    static let defaultRetentionInterval: TimeInterval =
        30 * 24 * 60 * 60

    private let defaults: UserDefaults
    private let storageKey: String
    private let maximumEventCount: Int
    private let retentionInterval: TimeInterval
    private let preferenceStore: any AnalyticsPreferenceStoring
    private let nowProvider: () -> Date

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = defaultStorageKey,
        maximumEventCount: Int = defaultMaximumEventCount,
        retentionInterval: TimeInterval = defaultRetentionInterval,
        preferenceStore: (any AnalyticsPreferenceStoring)? = nil,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.maximumEventCount = max(maximumEventCount, 1)
        self.retentionInterval = max(retentionInterval, 0)
        self.preferenceStore = preferenceStore
            ?? UserDefaultsAnalyticsPreferenceStore(
                defaults: defaults
            )
        self.nowProvider = nowProvider
    }

    func record(_ event: AnalyticsEventRecord) {
        guard preferenceStore.load() else {
            return
        }

        let now = nowProvider()
        guard isRetained(event, now: now) else {
            return
        }

        var storedEvents = retained(
            loadRawEvents(),
            now: now
        )
        storedEvents.append(event)
        storedEvents = capped(storedEvents)
        save(storedEvents)
    }

    func events() -> [AnalyticsEventRecord] {
        let rawEvents = loadRawEvents()
        let retainedEvents = capped(
            retained(
                rawEvents,
                now: nowProvider()
            )
        )

        if retainedEvents != rawEvents {
            save(retainedEvents)
        }

        return retainedEvents
    }

    func clear() {
        defaults.removeObject(forKey: storageKey)
    }

    private func loadRawEvents() -> [AnalyticsEventRecord] {
        guard let data = defaults.data(forKey: storageKey),
              let events = try? JSONDecoder().decode(
                [AnalyticsEventRecord].self,
                from: data
              ) else {
            return []
        }

        return events
    }

    private func retained(
        _ events: [AnalyticsEventRecord],
        now: Date
    ) -> [AnalyticsEventRecord] {
        events.filter {
            isRetained($0, now: now)
        }
    }

    private func isRetained(
        _ event: AnalyticsEventRecord,
        now: Date
    ) -> Bool {
        event.timestamp >= now.addingTimeInterval(
            -retentionInterval
        )
    }

    private func capped(
        _ events: [AnalyticsEventRecord]
    ) -> [AnalyticsEventRecord] {
        guard events.count > maximumEventCount else {
            return events
        }

        return Array(
            events.suffix(maximumEventCount)
        )
    }

    private func save(
        _ events: [AnalyticsEventRecord]
    ) {
        guard !events.isEmpty else {
            defaults.removeObject(forKey: storageKey)
            return
        }

        guard let data = try? JSONEncoder().encode(
            events
        ) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }
}

final class MemoryAnalyticsRecorder: AnalyticsRecording {
    private var storedEvents: [AnalyticsEventRecord]
    private let maximumEventCount: Int
    private let retentionInterval: TimeInterval
    private let preferenceStore: any AnalyticsPreferenceStoring
    private let nowProvider: () -> Date

    init(
        events: [AnalyticsEventRecord] = [],
        maximumEventCount: Int = 500,
        retentionInterval: TimeInterval =
            UserDefaultsAnalyticsRecorder.defaultRetentionInterval,
        preferenceStore: any AnalyticsPreferenceStoring =
            MemoryAnalyticsPreferenceStore(),
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.maximumEventCount = max(maximumEventCount, 1)
        self.retentionInterval = max(retentionInterval, 0)
        self.preferenceStore = preferenceStore
        self.nowProvider = nowProvider
        self.storedEvents = events
        prune()
    }

    func record(_ event: AnalyticsEventRecord) {
        guard preferenceStore.load() else {
            return
        }

        prune()

        guard isRetained(event) else {
            return
        }

        storedEvents.append(event)
        cap()
    }

    func events() -> [AnalyticsEventRecord] {
        prune()
        return storedEvents
    }

    func clear() {
        storedEvents = []
    }

    private func prune() {
        storedEvents = storedEvents.filter {
            isRetained($0)
        }
        cap()
    }

    private func isRetained(
        _ event: AnalyticsEventRecord
    ) -> Bool {
        event.timestamp >= nowProvider().addingTimeInterval(
            -retentionInterval
        )
    }

    private func cap() {
        if storedEvents.count > maximumEventCount {
            storedEvents = Array(
                storedEvents.suffix(maximumEventCount)
            )
        }
    }
}
