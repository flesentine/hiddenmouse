import SwiftUI

struct CommunitySubmissionsView: View {
    let contentLoader: ContentLoader
    let service: any CommunitySubmissionServicing

    @State private var submissions: [CommunitySubmission] = []
    @State private var isPresentingNew = false
    @State private var statusMessage: String?

    var body: some View {
        List {
            Section {
                Button {
                    isPresentingNew = true
                } label: {
                    Label(
                        "New Hunt Candidate",
                        systemImage: "plus.circle"
                    )
                }
            } footer: {
                Text(
                    "Community candidates never enter the trusted hunt catalog automatically. Every submission requires moderation and a separate editorial promotion step."
                )
            }

            if submissions.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Submissions Yet",
                        systemImage: "lightbulb",
                        description: Text(
                            "Save a draft when you notice a detail that could become a future hunt."
                        )
                    )
                }
            } else {
                Section("Your Candidates") {
                    ForEach(submissions) { submission in
                        NavigationLink {
                            CommunitySubmissionDetailView(
                                submissionID: submission.id,
                                service: service,
                                onChange: reload
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(submission.title)
                                    .font(.headline)

                                Text(submission.status.displayName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Text(
                                    "\(ParkCatalog.name(for: submission.parkID)) · \(submission.landID)"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            reload()
        }
        .sheet(isPresented: $isPresentingNew) {
            NavigationStack {
                CommunitySubmissionEditorView(
                    contentLoader: contentLoader,
                    service: service
                ) {
                    reload()
                    isPresentingNew = false
                }
            }
        }
    }

    private func reload() {
        submissions = service.submissions()
        statusMessage = service.moderationAvailable
            ? nil
            : "Moderation submission is not connected in this build. Drafts still stay safely on this device."
    }
}

private struct CommunitySubmissionEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let contentLoader: ContentLoader
    let service: any CommunitySubmissionServicing
    let onSaved: () -> Void

    @State private var parks: [ParkOption] = []
    @State private var lands: [Land] = []
    @State private var selectedParkID = ""
    @State private var selectedLandID = ""
    @State private var title = ""
    @State private var detailDescription = ""
    @State private var clueSuggestion = ""
    @State private var category: DiscoveryCategory?
    @State private var validationMessage: String?

    var body: some View {
        Form {
            Section("Location") {
                Picker("Park", selection: $selectedParkID) {
                    ForEach(parks) { park in
                        Text(park.name).tag(park.id)
                    }
                }
                .onChange(of: selectedParkID) {
                    refreshLands()
                }

                Picker("Land", selection: $selectedLandID) {
                    ForEach(lands) { land in
                        Text(land.name).tag(land.id)
                    }
                }
            }

            Section {
                TextField(
                    "Short title",
                    text: $title
                )

                TextField(
                    "What did you notice?",
                    text: $detailDescription,
                    axis: .vertical
                )
                .lineLimit(4...8)

                TextField(
                    "Suggested clue",
                    text: $clueSuggestion,
                    axis: .vertical
                )
                .lineLimit(2...5)

                Picker("Category", selection: $category) {
                    Text("Not Sure")
                        .tag(DiscoveryCategory?.none)

                    ForEach(
                        DiscoveryCategory.allCases,
                        id: \.rawValue
                    ) { category in
                        Text(categoryLabel(category))
                            .tag(DiscoveryCategory?.some(category))
                    }
                }
            } header: {
                Text("Candidate")
            } footer: {
                Text(
                    "Do not include precise GPS coordinates or private information. Editors verify the physical location separately."
                )
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("New Candidate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save Draft") {
                    save()
                }
            }
        }
        .onAppear {
            loadCatalogChoices()
        }
    }

    private func loadCatalogChoices() {
        guard let snapshot = try? contentLoader.load() else {
            return
        }

        parks = ParkCatalog.options(in: snapshot)
        if selectedParkID.isEmpty {
            selectedParkID = parks.first?.id ?? ""
        }
        refreshLands()
    }

    private func refreshLands() {
        guard let snapshot = try? contentLoader.load() else {
            lands = []
            selectedLandID = ""
            return
        }

        lands = snapshot.lands(inPark: selectedParkID)
        if !lands.contains(where: { $0.id == selectedLandID }) {
            selectedLandID = lands.first?.id ?? ""
        }
    }

    private func save() {
        let draft = CommunitySubmission(
            title: title,
            parkID: selectedParkID,
            landID: selectedLandID,
            detailDescription: detailDescription,
            clueSuggestion: clueSuggestion,
            categorySuggestion: category
        )

        switch service.saveDraft(draft) {
        case .savedDraft:
            onSaved()
        case .invalid(let issues):
            validationMessage = issues.joined(separator: " ")
        case .submitted, .refreshed, .unavailable, .notEditable:
            validationMessage = "Could not save this draft."
        }
    }

    private func categoryLabel(
        _ category: DiscoveryCategory
    ) -> String {
        switch category {
        case .hiddenMickey: "Hidden Mickey"
        case .hiddenCharacter: "Hidden Character"
        case .imagineeringDetail: "Imagineering Detail"
        case .movieReference: "Movie Reference"
        case .historicalDetail: "Historical Detail"
        case .easterEgg: "Easter Egg"
        case .secretFeature: "Secret Feature"
        }
    }
}

private struct CommunitySubmissionDetailView: View {
    let submissionID: UUID
    let service: any CommunitySubmissionServicing
    let onChange: () -> Void

    @State private var submission: CommunitySubmission?
    @State private var resultMessage: String?

    var body: some View {
        List {
            if let submission {
                Section("Candidate") {
                    LabeledContent("Title", value: submission.title)
                    LabeledContent(
                        "Status",
                        value: submission.status.displayName
                    )
                    LabeledContent(
                        "Park",
                        value: ParkCatalog.name(for: submission.parkID)
                    )
                    LabeledContent("Land", value: submission.landID)
                }

                Section("Detail") {
                    Text(submission.detailDescription)
                    Text(submission.clueSuggestion)
                        .foregroundStyle(.secondary)
                }

                if let note = submission.moderationNote,
                   !note.isEmpty {
                    Section("Moderation Note") {
                        Text(note)
                    }
                }

                Section {
                    if submission.status == .draft {
                        Button {
                            handle(service.submit(id: submissionID))
                        } label: {
                            Label(
                                "Submit for Review",
                                systemImage: "paperplane"
                            )
                        }
                        .disabled(!service.moderationAvailable)

                        Button(role: .destructive) {
                            service.deleteDraft(id: submissionID)
                            onChange()
                        } label: {
                            Label("Delete Draft", systemImage: "trash")
                        }
                    } else {
                        Button {
                            handle(service.refresh(id: submissionID))
                        } label: {
                            Label(
                                "Refresh Status",
                                systemImage: "arrow.clockwise"
                            )
                        }
                        .disabled(!service.moderationAvailable)
                    }
                } footer: {
                    Text(
                        "Approval means the candidate may move to editorial verification. It still does not become a hunt automatically."
                    )
                }

                if let resultMessage {
                    Section {
                        Text(resultMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Submission Unavailable",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
        .navigationTitle("Submission")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            reload()
        }
    }

    private func reload() {
        submission = service.submissions().first {
            $0.id == submissionID
        }
    }

    private func handle(
        _ result: CommunitySubmissionResult
    ) {
        switch result {
        case .savedDraft:
            resultMessage = "Draft saved."
        case .submitted:
            resultMessage = "Submitted for moderation."
        case .refreshed:
            resultMessage = "Status refreshed."
        case let .invalid(issues):
            resultMessage = issues.joined(separator: " ")
        case .unavailable:
            resultMessage = "Moderation service is not available."
        case .notEditable:
            resultMessage = "This submission cannot be changed in its current state."
        }

        reload()
        onChange()
    }
}
