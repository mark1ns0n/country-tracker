//
//  PresenceDayOverridesView.swift
//  CountryDaysTracker
//
//  Created on 15 March 2026.
//

import SwiftUI
import SwiftData

struct PresenceDayOverridesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = DateUtils.startOfDay(Date())
    @State private var countryCode = ResidencySettingsRepository.defaultHomeCountryCode
    @State private var notes = ""
    @State private var overrides: [PresenceDay] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Manual Override") {
                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )

                TextField("Country Code", text: $countryCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                TextField("Notes", text: $notes, axis: .vertical)

                Button("Apply Override") {
                    applyOverride()
                }

                Button("Clear Override For Date", role: .destructive) {
                    clearOverride()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("Existing Overrides") {
                if overrides.isEmpty {
                    Text("No manual overrides yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(overrides) { override in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(override.countryCode)
                                    .font(.headline)
                                Spacer()
                                Text(ResidencySummaryFormatter.formattedDate(override.date))
                                    .foregroundStyle(.secondary)
                            }

                            if let notes = override.notes {
                                Text(notes)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDate = override.date
                            countryCode = override.countryCode
                            notes = override.notes ?? ""
                        }
                    }
                }
            }
        }
        .navigationTitle("Manual Corrections")
        .onAppear { loadOverrides() }
        .onReceive(NotificationCenter.default.publisher(for: .presenceDaysDidChange)) { _ in
            loadOverrides()
        }
    }

    private func loadOverrides() {
        let repository = PresenceDayOverrideRepository(modelContext: modelContext)

        do {
            overrides = try repository.fetchManualOverrides()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load manual overrides"
        }
    }

    private func applyOverride() {
        let repository = PresenceDayOverrideRepository(modelContext: modelContext)

        do {
            try repository.applyOverride(
                for: selectedDate,
                countryCode: countryCode,
                notes: notes
            )
            countryCode = countryCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            loadOverrides()
        } catch PresenceDayOverrideError.invalidCountryCode {
            errorMessage = "Country code must be 2 uppercase letters"
        } catch {
            errorMessage = "Failed to apply manual override"
        }
    }

    private func clearOverride() {
        let repository = PresenceDayOverrideRepository(modelContext: modelContext)

        do {
            try repository.clearOverride(for: selectedDate)
            loadOverrides()
        } catch {
            errorMessage = "Failed to clear manual override"
        }
    }
}

#Preview {
    let container = try! AppModelSchema.makeContainer(inMemory: true)
    let context = ModelContext(container)
    _ = try? ResidencySettingsRepository(modelContext: context).ensureDefaults()
    context.insert(
        PresenceDay(
            date: DateUtils.startOfDay(Date()),
            countryCode: "RU",
            source: PresenceDayOverrideRepository.manualOverrideSource,
            isManualOverride: true,
            notes: "Preview correction"
        )
    )
    _ = try? context.save()

    return NavigationStack {
        PresenceDayOverridesView()
    }
    .modelContainer(container)
}
