//
//  CountryDaysTrackerApp.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI
import SwiftData

@main
struct CountryDaysTrackerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        do {
            let container = try AppModelSchema.makeContainer(inMemory: false)
            initializePersistentState(in: container)
            return container
        } catch {
            // Log error and try in-memory fallback
            print("❌ Failed to create persistent ModelContainer: \(error)")
            print("⚠️ Falling back to in-memory storage")
            
            // Attempt in-memory fallback
            do {
                let container = try AppModelSchema.makeContainer(inMemory: true)
                initializePersistentState(in: container)
                return container
            } catch {
                // If even in-memory fails, this is a critical error
                fatalError("Critical: Could not create any ModelContainer (persistent or in-memory): \(error)")
            }
        }
    }()

    private static func initializePersistentState(in container: ModelContainer) {
        let context = ModelContext(container)

        do {
            _ = try ResidencySettingsRepository(modelContext: context).ensureDefaults()
        } catch {
            print("⚠️ Failed to bootstrap residency defaults: \(error)")
        }

        do {
            _ = try PresenceDayBackfillService(modelContext: context).rebuildFromIntervals()
        } catch {
            print("⚠️ Failed to backfill presence days: \(error)")
        }

        ResidencyWidgetSyncService(modelContext: context).sync()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Self.initializePersistentState(in: sharedModelContainer)
        }
    }
}
