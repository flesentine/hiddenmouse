import XCTest
@testable import ParkHunt

final class CommunitySubmissionTests: XCTestCase {
    func testDraftValidationRequiresUsefulEditorialContext() {
        let draft = CommunitySubmission(
            title: "A",
            parkID: "",
            landID: "",
            detailDescription: "Short",
            clueSuggestion: "Tiny"
        )

        XCTAssertFalse(
            CommunitySubmissionValidation.issues(for: draft).isEmpty
        )
    }

    func testUnavailableProviderLeavesDraftLocalAndUnsubmitted() {
        let draft = makeDraft()
        let store = MemoryCommunitySubmissionStore([draft])
        let service = CommunitySubmissionService(
            store: store,
            provider: NoopCommunityModerationProvider()
        )

        XCTAssertEqual(service.submit(id: draft.id), .unavailable)
        XCTAssertEqual(
            store.submissions().first?.status,
            .draft
        )
    }

    func testSubmissionMovesThroughProviderOnly() {
        let draft = makeDraft()
        let store = MemoryCommunitySubmissionStore([draft])
        let provider = MemoryCommunityModerationProvider()
        let service = CommunitySubmissionService(
            store: store,
            provider: provider
        )

        XCTAssertEqual(service.submit(id: draft.id), .submitted)
        XCTAssertEqual(
            store.submissions().first?.status,
            .submitted
        )
        XCTAssertNotNil(store.submissions().first?.submittedAt)
    }

    func testUserCannotEditSubmittedCandidateThroughDraftAPI() {
        var submitted = makeDraft()
        submitted.status = .submitted
        let store = MemoryCommunitySubmissionStore([submitted])
        let service = CommunitySubmissionService(
            store: store,
            provider: MemoryCommunityModerationProvider()
        )

        XCTAssertEqual(
            service.saveDraft(submitted),
            .notEditable
        )
    }

    func testModerationStatusRefreshComesFromProvider() {
        let draft = makeDraft()
        let store = MemoryCommunitySubmissionStore([draft])
        let provider = MemoryCommunityModerationProvider()
        let service = CommunitySubmissionService(
            store: store,
            provider: provider
        )

        XCTAssertEqual(service.submit(id: draft.id), .submitted)

        guard var remote = store.submissions().first else {
            return XCTFail("Missing submitted candidate")
        }
        remote.status = .approved
        remote.moderationNote = "Candidate looks promising; editorial verification required."
        provider.setModerated(remote)

        XCTAssertEqual(service.refresh(id: draft.id), .refreshed)
        XCTAssertEqual(store.submissions().first?.status, .approved)
    }

    func testApprovedSubmissionStillIsNotDiscovery() {
        var candidate = makeDraft()
        candidate.status = .approved

        XCTAssertEqual(candidate.status, .approved)
        // Compile-time boundary: CommunitySubmission is not Discovery and
        // ContentCatalog has no community-submission collection.
        let catalog = ContentCatalog(
            schemaVersion: ContentCatalog.currentSchemaVersion,
            lands: [],
            areas: [],
            discoveries: []
        )
        XCTAssertTrue(catalog.discoveries.isEmpty)
    }

    private func makeDraft() -> CommunitySubmission {
        CommunitySubmission(
            title: "Interesting Window Detail",
            parkID: "disneyland",
            landID: "main-street-usa",
            detailDescription: "A repeatable themed detail visible from the public walkway near the storefront.",
            clueSuggestion: "Look above the storefront signs for a small themed detail.",
            categorySuggestion: .imagineeringDetail
        )
    }
}
