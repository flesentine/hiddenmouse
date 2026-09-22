import SwiftUI

struct SpoilerSettingsView: View {
    let store: any SpoilerPreferenceStoring

    @State private var selection: SpoilerPreference = .normal

    var body: some View {
        List {
            Section {
                ForEach(SpoilerPreference.allCases) { preference in
                    Button {
                        selection = preference
                        store.save(preference)
                    } label: {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: preference.systemImageName)
                                .font(.title3)
                                .frame(width: 28)
                                .foregroundStyle(.primary)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(preference.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(preference.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(
                                        horizontal: false,
                                        vertical: true
                                    )
                            }

                            Spacer()

                            if selection == preference {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.primary)
                                    .accessibilityLabel("Selected")
                            }
                        }
                        .padding(.vertical, 6)
                        .parkHuntTapTarget()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        "\(preference.displayName). \(preference.description)"
                    )
                    .accessibilityValue(
                        selection == preference ? "Selected" : "Not selected"
                    )
                }
            } header: {
                Text("How much help should Park Hunt offer?")
            } footer: {
                Text(
                    "Changing this never reveals anything automatically. It only changes which help button is easiest to reach."
                )
            }
        }
        .navigationTitle("Help Style")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            selection = store.load()
        }
    }
}

#Preview {
    NavigationStack {
        SpoilerSettingsView(
            store: MemorySpoilerPreferenceStore()
        )
    }
}
