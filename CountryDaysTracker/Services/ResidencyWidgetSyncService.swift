//
//  ResidencyWidgetSyncService.swift
//  CountryDaysTracker
//
//  Created on 15 March 2026.
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
final class ResidencyWidgetSyncService {
    private let modelContext: ModelContext
    private let snapshotService: ResidencySnapshotService

    init(
        modelContext: ModelContext,
        snapshotService: ResidencySnapshotService? = nil
    ) {
        self.modelContext = modelContext
        self.snapshotService = snapshotService ?? ResidencySnapshotService(modelContext: modelContext)
    }

    func sync() {
        do {
            let evaluation = try snapshotService.currentEvaluation()
            let snapshot = ResidencyWidgetSnapshot(
                homeCountryCode: evaluation.homeCountryCode,
                daysUsed: evaluation.daysUsed,
                daysRemaining: evaluation.daysRemaining,
                nextSafeEntryDate: evaluation.nextSafeEntryDate,
                safeUntilDate: evaluation.latestSafeExitDateIfEnterToday,
                lastUpdated: Date()
            )
            try save(snapshot)
        } catch {
            print("Failed to sync residency widget snapshot: \(error)")
        }
    }

    private func save(_ snapshot: ResidencyWidgetSnapshot) throws {
        let defaults = UserDefaults(suiteName: ResidencyWidgetStore.suiteName)
        let data = try JSONEncoder().encode(snapshot)
        defaults?.set(data, forKey: ResidencyWidgetStore.snapshotKey)
        WidgetCenter.shared.reloadTimelines(ofKind: ResidencyWidgetStore.widgetKind)
    }
}
