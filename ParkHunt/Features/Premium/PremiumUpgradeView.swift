import SwiftUI

struct PremiumUpgradeView: View {
    let entitlementStore: any PremiumEntitlementStoring

    @State private var entitlement: PremiumEntitlement = .free

    var body: some View {
        List {
            Section {
                Label(
                    entitlement.isPremium ? "Premium Active" : "Free",
                    systemImage: entitlement.isPremium
                        ? "checkmark.seal.fill"
                        : "lock"
                )
            } header: {
                Text("Plan")
            }

            Section("Premium Features") {
                Label(
                    "5- and 8-hunt Today’s Hunt routes",
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up"
                )

                Label(
                    "Ad-free browsing",
                    systemImage: "rectangle.slash"
                )
            }

            Section {
                ContentUnavailableView(
                    "Purchases Not Connected Yet",
                    systemImage: "creditcard",
                    description: Text(
                        "The entitlement boundary is ready, but StoreKit or another payment provider has not been connected yet."
                    )
                )
            }
        }
        .navigationTitle("Park Hunt Premium")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            entitlement = entitlementStore.load()
        }
    }
}

#Preview {
    NavigationStack {
        PremiumUpgradeView(
            entitlementStore: MemoryPremiumEntitlementStore()
        )
    }
}
