import SwiftUI

struct LegalInfoView: View {
    var body: some View {
        List {
            Section("Privacy") {
                Label {
                    Text(
                        "Nearby uses location only while you are using the app. Park Hunt requests one foreground fix, never saves the coordinates, and discards the in-memory fix when Nearby closes or the app backgrounds."
                    )
                } icon: {
                    Image(systemName: "location")
                }

                Label {
                    Text(
                        "Hunt progress, Help Style, haptic preferences, and optional prototype product-use analytics are stored locally on this device."
                    )
                } icon: {
                    Image(systemName: "iphone")
                }

                Label {
                    Text(
                        "Local Analytics can be turned off or cleared in Settings. Stored analytics are automatically removed after 30 days and capped at 500 events."
                    )
                } icon: {
                    Image(systemName: "chart.bar")
                }

                Label {
                    Text(
                        "Analytics never include precise location, clue or reveal text, discovery titles, image names, tags, or a user/device identifier, and there is no analytics upload path."
                    )
                } icon: {
                    Image(systemName: "hand.raised")
                }
            }

            Section("Independent App") {
                Text(
                    "Park Hunt is an independent companion app and is not affiliated with, sponsored by, or endorsed by Disney or other venue operators."
                )

                Text(
                    "Venue, attraction, and trademark names belong to their respective owners."
                )
            }

            Section("Content") {
                Text(
                    "Park Hunt is designed around original clues, descriptions, and owned or appropriately licensed reference imagery."
                )
            }
        }
        .navigationTitle("Privacy & Legal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LegalInfoView()
    }
}
