//
//  ResidencyDashboardView.swift
//  CountryDaysTracker
//
//  Created on 15 March 2026.
//

import SwiftUI
import SwiftData

struct ResidencyDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var evaluation: ResidencyEvaluation?
    @State private var homeCountryCode = ""
    @State private var activeRuleTitle = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let evaluation {
                        ResidencySummaryContent(
                            evaluation: evaluation,
                            accentCountryCode: homeCountryCode
                        )
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    } else {
                        ProgressView("Loading residency status...")
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Risk")
                        if !activeRuleTitle.isEmpty {
                            Text(activeRuleTitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Decision") {
                    if let evaluation {
                        Text(decisionMessage(for: evaluation))
                            .font(.headline)
                            .foregroundStyle(evaluation.daysRemaining == 0 ? .red : .primary)

                        Text(subheadline(for: evaluation))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("What Next") {
                    NavigationLink("Plan Trip") {
                        ResidencyPlannerView()
                    }

                    NavigationLink("Manual Corrections") {
                        PresenceDayOverridesView()
                    }

                    NavigationLink("Open Settings") {
                        SettingsHostView()
                    }
                }
            }
            .navigationTitle("Residency")
        }
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .stayIntervalsDidChange)) { _ in
            reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .presenceDaysDidChange)) { _ in
            reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .residencySettingsDidChange)) { _ in
            reload()
        }
    }

    private func reload() {
        let settingsRepository = ResidencySettingsRepository(modelContext: modelContext)
        let snapshotService = ResidencySnapshotService(modelContext: modelContext)

        do {
            let profile = try settingsRepository.ensureDefaults()
            let currentEvaluation = try snapshotService.currentEvaluation()
            homeCountryCode = profile.homeCountryCode
            activeRuleTitle = currentEvaluation.ruleTitle
            evaluation = currentEvaluation
            errorMessage = nil
        } catch {
            evaluation = nil
            errorMessage = "Failed to load residency status"
        }
    }

    private func decisionMessage(for evaluation: ResidencyEvaluation) -> String {
        if evaluation.daysRemaining == 0 {
            return "Going home today is not safe under the active rule."
        }
        return "You can currently spend up to \(evaluation.maxSafeStayIfEnterToday) days in \(evaluation.homeCountryCode)."
    }

    private func subheadline(for evaluation: ResidencyEvaluation) -> String {
        let nextSafeEntry = ResidencySummaryFormatter.formattedDate(evaluation.nextSafeEntryDate)
        let latestSafeExit = ResidencySummaryFormatter.formattedDate(evaluation.latestSafeExitDateIfEnterToday)

        if evaluation.daysRemaining == 0 {
            return "Next safe entry: \(nextSafeEntry)."
        }

        return "If you enter now, leave by \(latestSafeExit) to stay within the active rule."
    }
}

private struct SettingsHostView: View {
    @EnvironmentObject private var locationService: LocationService

    var body: some View {
        SettingsViewContent(locationService: locationService)
    }
}

#Preview {
    let container = try! AppModelSchema.makeContainer(inMemory: true)
    let context = ModelContext(container)
    _ = try? ResidencySettingsRepository(modelContext: context).ensureDefaults()
    context.insert(PresenceDay(date: DateUtils.startOfDay(Date()), countryCode: "RU", source: "preview"))
    _ = try? context.save()
    let repo = StayRepository(modelContext: context)
    let engine = StayEngine(repository: repo)

    return ResidencyDashboardView()
        .environmentObject(LocationService(stayEngine: engine, repository: repo))
        .modelContainer(container)
}
