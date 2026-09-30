import SwiftUI

struct FieldTestFeedbackView: View {
    let discovery: Discovery
    let store: any FieldTestFeedbackStoring

    @Environment(\.dismiss) private var dismiss

    @State private var accuracy: FieldTestAccuracyRating = .accurate
    @State private var clueQuality: FieldTestClueRating = .clear
    @State private var nearbyUsefulness: FieldTestNearbyRating = .notUsed
    @State private var selectedIssues: Set<FieldTestIssue> = []
    @State private var notes = ""

    init(
        discovery: Discovery,
        store: any FieldTestFeedbackStoring = UserDefaultsFieldTestFeedbackStore()
    ) {
        self.discovery = discovery
        self.store = store
    }

    var body: some View {
        Form {
            Section {
                Text(discovery.title)
                    .font(.headline)

                Text(discovery.id)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            } header: {
                Text("Hunt")
            }

            Section("Accuracy") {
                Picker("Location accuracy", selection: $accuracy) {
                    ForEach(FieldTestAccuracyRating.allCases) { rating in
                        Text(rating.displayName).tag(rating)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Clue quality") {
                Picker("Clue quality", selection: $clueQuality) {
                    ForEach(FieldTestClueRating.allCases) { rating in
                        Text(rating.displayName).tag(rating)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Nearby") {
                Picker("Nearby usefulness", selection: $nearbyUsefulness) {
                    ForEach(FieldTestNearbyRating.allCases) { rating in
                        Text(rating.displayName).tag(rating)
                    }
                }
            }

            Section("Issues") {
                ForEach(FieldTestIssue.allCases) { issue in
                    Button {
                        toggle(issue)
                    } label: {
                        HStack {
                            Text(issue.displayName)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(
                                systemName: selectedIssues.contains(issue)
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Notes") {
                TextField(
                    "What should be fixed or rechecked?",
                    text: $notes,
                    axis: .vertical
                )
                .lineLimit(3...8)
            }

            Section {
                Button {
                    save()
                } label: {
                    Label("Save Field Feedback", systemImage: "tray.and.arrow.down.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("field-test.feedback.save")
            } footer: {
                Text("Saved only on this device. No precise location is saved.")
            }
        }
        .navigationTitle("Field Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    private func toggle(_ issue: FieldTestIssue) {
        if selectedIssues.contains(issue) {
            selectedIssues.remove(issue)
        } else {
            selectedIssues.insert(issue)
        }
    }

    private func save() {
        store.save(
            FieldTestFeedbackRecord(
                discoveryID: discovery.id,
                discoveryTitle: discovery.title,
                accuracy: accuracy,
                clueQuality: clueQuality,
                nearbyUsefulness: nearbyUsefulness,
                issues: Array(selectedIssues),
                notes: notes
            )
        )
        dismiss()
    }
}

struct FieldTestFeedbackLogView: View {
    private let store = UserDefaultsFieldTestFeedbackStore()

    @State private var records: [FieldTestFeedbackRecord] = []
    @State private var showClearConfirmation = false

    var body: some View {
        List {
            if records.isEmpty {
                ContentUnavailableView(
                    "No Field Feedback Yet",
                    systemImage: "testtube.2",
                    description: Text("Save feedback from a hunt during the Disneyland field test.")
                )
            } else {
                Section {
                    ShareLink(
                        item: store.exportJSON(),
                        subject: Text("Park Hunt Field Test Feedback"),
                        message: Text("Structured JSON feedback from the Disneyland field test.")
                    ) {
                        Label("Share Feedback JSON", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear Field Feedback", systemImage: "trash")
                    }
                }

                Section("Saved Feedback") {
                    ForEach(records) { record in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(record.discoveryTitle)
                                .font(.headline)

                            Text(record.timestamp, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(
                                "Accuracy: \(record.accuracy.displayName) · Clues: \(record.clueQuality.displayName) · Nearby: \(record.nearbyUsefulness.displayName)"
                            )
                            .font(.subheadline)

                            if !record.issues.isEmpty {
                                Text(record.issues.map(\.displayName).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if !record.notes.isEmpty {
                                Text(record.notes)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Field Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            reload()
        }
        .alert(
            "Clear Field Feedback?",
            isPresented: $showClearConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                store.clear()
                reload()
            }
        } message: {
            Text("This permanently deletes the saved field-test feedback on this device.")
        }
    }

    private func reload() {
        records = store.records()
    }
}
