import SwiftUI

struct RootView: View {
    let environment: AppEnvironment

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "scope")
                    .font(.system(size: 52, weight: .semibold))
                    .accessibilityHidden(true)

                Text("Park Hunt")
                    .font(.largeTitle.bold())

                Text("Discover what everyone else walks past.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                #if DEBUG
                Text(environment.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Build environment: \(environment.rawValue)")
                #endif
            }
            .padding(24)
            .navigationTitle("Park Hunt")
        }
    }
}

#Preview {
    RootView(environment: .development)
}
