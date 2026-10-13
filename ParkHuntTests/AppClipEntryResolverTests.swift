import XCTest
@testable import ParkHunt

final class AppClipEntryResolverTests: XCTestCase {
    func testResolvesUniversalLinkHuntPath() {
        let url = URL(
            string: "https://example.com/hunt/main-street-window"
        )!

        XCTAssertEqual(
            AppClipEntryResolver.resolve(url: url),
            .hunt(discoveryID: "main-street-window")
        )
    }

    func testRejectsCustomSchemeInvocation() {
        let url = URL(
            string: "parkhunt:///hunt/main-street-window"
        )!

        XCTAssertNil(
            AppClipEntryResolver.resolve(url: url)
        )
    }

    func testRejectsNonHuntPaths() {
        XCTAssertNil(
            AppClipEntryResolver.resolve(
                url: URL(string: "https://example.com/map")!
            )
        )
    }

    func testValidationRejectsUnknownDiscovery() {
        let snapshot = ContentSnapshot(
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: [],
                areas: [],
                discoveries: []
            )
        )

        XCTAssertNil(
            AppClipEntryResolver.validatedDiscoveryID(
                from: .hunt(discoveryID: "missing"),
                snapshot: snapshot
            )
        )
    }
}
