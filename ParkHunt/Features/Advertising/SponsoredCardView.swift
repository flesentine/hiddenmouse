import SwiftUI

struct SponsoredCardView: View {
    let placement: AdPlacement
    let entitlementStore: any PremiumEntitlementStoring
    let provider: any AdvertisingProviding

    @State private var entitlement: PremiumEntitlement = .free

    var body: some View {
        Group {
            if AdPolicy.shouldShow(
                placement: placement,
                entitlement: entitlement,
                provider: provider
            ),
               let creative = provider.creative(for: placement) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sponsored")
                            .font(.caption2.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(creative.sponsor)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(creative.headline)
                        .font(.subheadline.weight(.semibold))

                    Text(creative.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    .background,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.separator.opacity(0.35), lineWidth: 0.5)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "Sponsored. \(creative.sponsor). \(creative.headline)"
                )
            }
        }
        .onAppear {
            entitlement = entitlementStore.load()
        }
    }
}
