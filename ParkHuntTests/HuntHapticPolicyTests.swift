import XCTest
@testable import ParkHunt

final class HuntHapticPolicyTests: XCTestCase {
    func testNormalClueUsesLightImpact() {
        let action = HuntProgressionAction.revealHint(
            Hint(
                id: "h2",
                order: 2,
                text: "Look higher."
            )
        )

        let event = HuntHapticPolicy.event(for: action)

        XCTAssertEqual(event, .clueRevealed)
        XCTAssertEqual(
            HuntHapticPolicy.pattern(for: event),
            .impact(.light)
        )
    }

    func testDetailedHelpUsesMediumImpact() {
        let action = HuntProgressionAction.revealHint(
            Hint(
                id: "detail",
                order: 3,
                text: "Look above the arch.",
                kind: .detailed
            )
        )

        let event = HuntHapticPolicy.event(for: action)

        XCTAssertEqual(event, .detailedHelpRevealed)
        XCTAssertEqual(
            HuntHapticPolicy.pattern(for: event),
            .impact(.medium)
        )
    }

    func testFullRevealUsesRigidImpact() {
        let event = HuntHapticPolicy.event(
            for: .revealLocation
        )

        XCTAssertEqual(event, .fullRevealOpened)
        XCTAssertEqual(
            HuntHapticPolicy.pattern(for: event),
            .impact(.rigid)
        )
    }

    func testFoundUsesSuccessNotificationPattern() {
        XCTAssertEqual(
            HuntHapticPolicy.pattern(
                for: .discoveryFound
            ),
            .success
        )
    }

    func testHapticHierarchyKeepsFoundDistinctFromHelp() {
        let helpPatterns: [HuntHapticPattern] = [
            HuntHapticPolicy.pattern(for: .clueRevealed),
            HuntHapticPolicy.pattern(for: .detailedHelpRevealed),
            HuntHapticPolicy.pattern(for: .fullRevealOpened)
        ]

        XCTAssertFalse(helpPatterns.contains(.success))
    }
}
