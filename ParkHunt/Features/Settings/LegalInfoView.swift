import SwiftUI

struct LegalInfoView: View {
    var body: some View {
        List {
            Section("Privacy") {
                Label {
                    Text(
                        "Nearby uses location only while you are using the app. Park Hunt takes a foreground fix when requested and does not store location history."
                    )
                } icon: {
                    Image(systemName: "location")
                }

                Label {
                    Text(
                        "Hunt progress, Help Style, and haptic preferences are stored locally on this device."
                    )
                } icon: {
                    Image(systemName: "iphone")
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
