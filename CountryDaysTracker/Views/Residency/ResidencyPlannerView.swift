//
//  ResidencyPlannerView.swift
//  CountryDaysTracker
//
//  Created on 15 March 2026.
//

import SwiftUI
import SwiftData

struct ResidencyPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var arrivalDate = DateUtils.startOfDay(Date())
    @State private var exitDate = Calendar.current.date(
        byAdding: .day,
        value: 13,
        to: DateUtils.startOfDay(Date())
    ) ?? DateUtils.startOfDay(Date())
    @State private var targetCountryCode = ResidencySettingsRepository.defaultHomeCountryCode
    @State private var homeCountryCode = ResidencySettingsRepository.defaultHomeCountryCode
    @State private var plan: ResidencyStayPlan?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Trip Inputs") {
                DatePicker(
                    "Arrival Date",
                    selection: $arrivalDate,
                    in: minimumArrivalDate...,
                    displayedComponents: .date
                )

                DatePicker(
                    "Exit Date",
                    selection: $exitDate,
                    in: arrivalDate...,
                    displayedComponents: .date
                )

                TextField("Destination Country Code", text: $targetCountryCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                Text("Trips to \(homeCountryCode) add residency-risk days. Trips to other countries are evaluated as non-home travel.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Result") {
                if let plan {
                    Text(resultHeadline(for: plan))
                        .font(.headline)
                        .foregroundStyle(plan.isScenarioSafe ? Color.primary : .red)

                    resultRow(
                        title: "Destination",
                        value: plan.targetCountryCode
                    )
                    resultRow(
                        title: "Trip Length",
                        value: "\(plan.requestedStayLengthDays) days"
                    )
                    resultRow(
                        title: "Projected \(plan.homeCountryCode) Days After Trip",
                        value: "\(plan.projectedDaysUsedAfterScenario)"
                    )
                    resultRow(
                        title: "Safe \(plan.homeCountryCode) Days Left After Trip",
                        value: "\(plan.projectedDaysRemainingAfterScenario)"
                    )
                    resultRow(
                        title: "Earliest Safe \(plan.homeCountryCode) Arrival After This Trip",
                        value: ResidencySummaryFormatter.formattedDate(plan.earliestSafeArrivalDateForRequestedStay)
                    )

                    if plan.affectsHomeCountryDays {
                        resultRow(
                            title: "Max Safe \(plan.homeCountryCode) Stay From Entry Date",
                            value: "\(plan.maxSafeStayLengthDays) days"
                        )
                        resultRow(
                            title: "Latest Safe \(plan.homeCountryCode) Exit",
                            value: ResidencySummaryFormatter.formattedDate(plan.latestSafeExitDateForScenario)
                        )
                    }

                    if let breachDate = plan.breachDate {
                        Text(
                            "If you enter \(plan.homeCountryCode) on \(ResidencySummaryFormatter.formattedDate(plan.arrivalDate)) and stay through \(ResidencySummaryFormatter.formattedDate(plan.exitDate)), the first unsafe day is \(ResidencySummaryFormatter.formattedDate(breachDate))."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    } else if !plan.affectsHomeCountryDays {
                        Text("This trip does not add \(plan.homeCountryCode) residency days.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                } else {
                    ProgressView("Calculating trip plan...")
                }
            }
        }
        .navigationTitle("Plan Trip")
        .onAppear { reloadPlan() }
        .onChange(of: arrivalDate) { _, _ in
            if exitDate < arrivalDate {
                exitDate = arrivalDate
            }
            reloadPlan()
        }
        .onChange(of: exitDate) { _, _ in
            reloadPlan()
        }
        .onChange(of: targetCountryCode) { _, _ in
            reloadPlan()
        }
        .onReceive(NotificationCenter.default.publisher(for: .stayIntervalsDidChange)) { _ in
            reloadPlan()
        }
        .onReceive(NotificationCenter.default.publisher(for: .residencySettingsDidChange)) { _ in
            reloadPlan()
        }
        .onReceive(NotificationCenter.default.publisher(for: .presenceDaysDidChange)) { _ in
            reloadPlan()
        }
    }

    private func reloadPlan() {
        let normalizedTargetCountryCode = targetCountryCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard isValidCountryCode(normalizedTargetCountryCode) else {
            plan = nil
            errorMessage = "Destination country code must be 2 uppercase letters"
            return
        }

        let settingsRepository = ResidencySettingsRepository(modelContext: modelContext)
        let snapshotService = ResidencySnapshotService(modelContext: modelContext)

        do {
            let profile = try settingsRepository.ensureDefaults()
            homeCountryCode = profile.homeCountryCode
            plan = try snapshotService.planStay(
                arrivalDate: arrivalDate,
                exitDate: exitDate,
                targetCountryCode: normalizedTargetCountryCode
            )
            errorMessage = nil
        } catch {
            plan = nil
            errorMessage = "Failed to calculate trip plan"
        }
    }

    private func resultHeadline(for plan: ResidencyStayPlan) -> String {
        if !plan.affectsHomeCountryDays {
            return "This trip does not increase your \(plan.homeCountryCode) day count."
        }
        if plan.isScenarioSafe {
            return "This \(plan.requestedStayLengthDays)-day trip fits within your current safe limit."
        }
        return "This \(plan.requestedStayLengthDays)-day trip would exceed your current safe limit."
    }

    private func resultRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private var minimumArrivalDate: Date {
        DateUtils.startOfDay(Date())
    }

    private func isValidCountryCode(_ code: String) -> Bool {
        code.range(of: "^[A-Z]{2}$", options: .regularExpression) != nil
    }
}

#Preview {
    let container = try! AppModelSchema.makeContainer(inMemory: true)
    let context = ModelContext(container)
    _ = try? ResidencySettingsRepository(modelContext: context).ensureDefaults()
    context.insert(PresenceDay(date: DateUtils.startOfDay(Date()), countryCode: "RU", source: "preview"))
    _ = try? context.save()

    return NavigationStack {
        ResidencyPlannerView()
    }
    .modelContainer(container)
}
