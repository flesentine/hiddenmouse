import XCTest
@testable import ParkHunt

final class DomainValidationTests: XCTestCase {
    func testLandValidationRejectsMissingIdentityAndName() {
        let land = Land(id: "", parkID: "", name: "  ", sortOrder: 0)
        let issues = DomainValidator.validate(land)

        XCTAssertTrue(issues.contains(.emptyIdentifier(entity: "Land")))
        XCTAssertTrue(issues.contains(.emptyReference(discoveryID: "", field: "parkID")))
        XCTAssertTrue(issues.contains(.emptyName(entity: "Land", id: "")))
    }

    func testAttractionAreaValidationRejectsMissingIdentityAndName() {
        let area = AttractionArea(
            id: "",
            landID: "",
            name: "",
            kind: .area,
            sortOrder: 0
        )
        let issues = DomainValidator.validate(area)

        XCTAssertTrue(issues.contains(.emptyIdentifier(entity: "AttractionArea")))
        XCTAssertTrue(issues.contains(.emptyReference(discoveryID: "", field: "landID")))
        XCTAssertTrue(issues.contains(.emptyName(entity: "AttractionArea", id: "")))
    }

    func testDiscoveryValidationRejectsEmptyRequiredText() {
        let discovery = Discovery(
            id: "bad",
            title: "",
            parkID: "",
            landID: "",
            areaID: nil,
            category: .secretFeature,
            difficulty: .easy,
            location: nil,
            hints: [Hint(id: "h1", order: 0, text: " ")],
            revealDescription: "",
            revealImageName: nil,
            verificationStatus: .unverified,
            lastVerifiedAt: nil,
            isIndoor: true,
            tags: []
        )

        let issues = DomainValidator.validate(discovery)

        XCTAssertTrue(issues.contains(.emptyTitle(discoveryID: "bad")))
        XCTAssertTrue(issues.contains(.emptyReference(discoveryID: "bad", field: "parkID")))
        XCTAssertTrue(issues.contains(.emptyReference(discoveryID: "bad", field: "landID")))
        XCTAssertTrue(issues.contains(.nonPositiveHintOrder(discoveryID: "bad", order: 0)))
        XCTAssertTrue(issues.contains(.emptyHintText(discoveryID: "bad", hintID: "h1")))
        XCTAssertTrue(issues.contains(.emptyRevealDescription(discoveryID: "bad")))
    }
}
