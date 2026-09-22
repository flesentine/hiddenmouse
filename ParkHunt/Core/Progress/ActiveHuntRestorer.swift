import Foundation

enum ActiveHuntRestorer {
    static func restorableSession(
        storedSession: ActiveHuntSession?,
        snapshot: ContentSnapshot,
        progress: UserProgress
    ) -> ActiveHuntSession? {
        guard let storedSession,
              snapshot.discovery(id: storedSession.discoveryID) != nil,
              !progress.progress(
                for: storedSession.discoveryID
              ).isFound else {
            return nil
        }

        return storedSession
    }
}
