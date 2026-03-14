//
//  PresenceDayOverrideRepository.swift
//  CountryDaysTracker
//
//  Created on 15 March 2026.
//

import Foundation
import SwiftData

@MainActor
final class PresenceDayOverrideRepository {
    static let manualOverrideSource = "manual.override"

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchManualOverrides(limit: Int = 100) throws -> [PresenceDay] {
        var descriptor = FetchDescriptor<PresenceDay>(
            predicate: #Predicate { $0.isManualOverride == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func applyOverride(
        for date: Date,
        countryCode: String,
        notes: String? = nil
    ) throws {
        let normalizedDay = DateUtils.startOfDay(date)
        let normalizedCountryCode = normalizeCountryCode(countryCode)
        guard isValidCountryCode(normalizedCountryCode) else {
            throw PresenceDayOverrideError.invalidCountryCode
        }

        for existingDay in try fetchPresenceDays(on: normalizedDay) {
            modelContext.delete(existingDay)
        }

        modelContext.insert(
            PresenceDay(
                date: normalizedDay,
                countryCode: normalizedCountryCode,
                source: Self.manualOverrideSource,
                isManualOverride: true,
                notes: normalizeNotes(notes)
            )
        )
        try modelContext.save()
        ResidencyWidgetSyncService(modelContext: modelContext).sync()
        NotificationCenter.default.post(name: .presenceDaysDidChange, object: nil)
    }

    func clearOverride(for date: Date) throws {
        let normalizedDay = DateUtils.startOfDay(date)
        let manualOverrides = try fetchManualOverrides(on: normalizedDay)
        guard !manualOverrides.isEmpty else { return }

        for override in manualOverrides {
            modelContext.delete(override)
        }
        try modelContext.save()

        _ = try PresenceDayBackfillService(modelContext: modelContext).rebuildFromIntervals()
        ResidencyWidgetSyncService(modelContext: modelContext).sync()
        NotificationCenter.default.post(name: .presenceDaysDidChange, object: nil)
    }

    private func fetchPresenceDays(on day: Date) throws -> [PresenceDay] {
        let descriptor = FetchDescriptor<PresenceDay>(
            predicate: #Predicate { $0.date == day }
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchManualOverrides(on day: Date) throws -> [PresenceDay] {
        let descriptor = FetchDescriptor<PresenceDay>(
            predicate: #Predicate { $0.date == day && $0.isManualOverride == true }
        )
        return try modelContext.fetch(descriptor)
    }

    private func normalizeCountryCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func normalizeNotes(_ notes: String?) -> String? {
        let normalized = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized?.isEmpty == true ? nil : normalized
    }

    private func isValidCountryCode(_ code: String) -> Bool {
        code.range(of: "^[A-Z]{2}$", options: .regularExpression) != nil
    }
}

enum PresenceDayOverrideError: Error {
    case invalidCountryCode
}
