//
//  PresenceDayBackfillService.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation
import SwiftData

@MainActor
final class PresenceDayBackfillService {
    private let modelContext: ModelContext
    private let builder: PresenceDayBuilder

    init(
        modelContext: ModelContext,
        builder: PresenceDayBuilder = PresenceDayBuilder()
    ) {
        self.modelContext = modelContext
        self.builder = builder
    }

    /// Assumption: a country counts for a calendar day if any part of a stay interval
    /// overlaps that local day in the active calendar. Rebuild deletes only derived rows,
    /// preserves manual overrides, and is safe to rerun.
    @discardableResult
    func rebuildFromIntervals() throws -> Int {
        let intervals = try fetchIntervals()
        let derivedRecords = builder.build(from: intervals)
        let manualOverrideDates = try fetchManualOverrideDates()
        let existingDerivedDays = try fetchDerivedPresenceDays()

        for day in existingDerivedDays {
            modelContext.delete(day)
        }

        for record in derivedRecords where !manualOverrideDates.contains(record.date) {
            modelContext.insert(
                PresenceDay(
                    date: record.date,
                    countryCode: record.countryCode,
                    source: record.source
                )
            )
        }

        if !existingDerivedDays.isEmpty || !derivedRecords.isEmpty {
            try modelContext.save()
        }

        return derivedRecords.count - derivedRecords.filter {
            manualOverrideDates.contains($0.date)
        }.count
    }

    private func fetchIntervals() throws -> [StayInterval] {
        let descriptor = FetchDescriptor<StayInterval>(
            sortBy: [SortDescriptor(\.entryAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchDerivedPresenceDays() throws -> [PresenceDay] {
        let descriptor = FetchDescriptor<PresenceDay>(
            predicate: #Predicate { $0.isManualOverride == false }
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchManualOverrideDates() throws -> Set<Date> {
        let descriptor = FetchDescriptor<PresenceDay>(
            predicate: #Predicate { $0.isManualOverride == true }
        )

        return try Set(modelContext.fetch(descriptor).map(\.date))
    }
}
