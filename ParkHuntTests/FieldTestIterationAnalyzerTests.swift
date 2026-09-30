import XCTest
@testable import ParkHunt

final class FieldTestIterationAnalyzerTests: XCTestCase {
    func testWrongLocationIsCritical() {
        let item = try! XCTUnwrap(
            FieldTestIterationAnalyzer.makeQueue(
                records: [
                    FieldTestFeedbackRecord(
                        timestamp: Date(timeIntervalSince1970: 1),
                        discoveryID: "hunt-1",
                        discoveryTitle: "Hunt 1",
                        accuracy: .wrong,
                        clueQuality: .clear,
                        nearbyUsefulness: .useful
                    )
                ]
            ).first
        )

        XCTAssertEqual(item.priority, .critical)
        XCTAssertTrue(item.reasons.contains { $0.contains("wrong-location") })
    }

    func testRepeatedConfusingCluesBecomeHighPriority() {
        let records = (1...2).map { index in
            FieldTestFeedbackRecord(
                timestamp: Date(timeIntervalSince1970: TimeInterval(index)),
                discoveryID: "hunt-1",
                discoveryTitle: "Hunt 1",
                accuracy: .accurate,
                clueQuality: .confusing,
                nearbyUsefulness: .okay
            )
        }

        XCTAssertEqual(
            FieldTestIterationAnalyzer.makeQueue(records: records).first?.priority,
            .high
        )
    }

    func testQueueSortsHighestPriorityFirst() {
        let records = [
            FieldTestFeedbackRecord(
                discoveryID: "monitor",
                discoveryTitle: "Monitor",
                accuracy: .accurate,
                clueQuality: .clear,
                nearbyUsefulness: .useful
            ),
            FieldTestFeedbackRecord(
                discoveryID: "critical",
                discoveryTitle: "Critical",
                accuracy: .wrong,
                clueQuality: .clear,
                nearbyUsefulness: .useful
            )
        ]

        XCTAssertEqual(
            FieldTestIterationAnalyzer.makeQueue(records: records).map(\.discoveryID),
            ["critical", "monitor"]
        )
    }
}
