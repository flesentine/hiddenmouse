import UIKit

struct BundledRevealImageStore {
    let bundle: Bundle

    init(
        bundle: Bundle = Bundle(for: ParkHuntBundleToken.self)
    ) {
        self.bundle = bundle
    }

    func image(named name: String) -> UIImage? {
        UIImage(
            named: name,
            in: bundle,
            compatibleWith: nil
        )
    }

    func containsImage(named name: String) -> Bool {
        image(named: name) != nil
    }
}
