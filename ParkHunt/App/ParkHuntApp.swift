import SwiftUI

@main
struct ParkHuntApp: App {
    private let environment = AppEnvironment.current

    var body: some Scene {
        WindowGroup {
            RootView(environment: environment)
        }
    }
}
