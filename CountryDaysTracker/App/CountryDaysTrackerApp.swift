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
    var sharedModelContainer: ModelContainer = {
        do {
            let container = try AppModelSchema.makeContainer(inMemory: false)
            bootstrapResidencyDefaults(in: container)
            return container
        } catch {
            // Log error and try in-memory fallback
            print("❌ Failed to create persistent ModelContainer: \(error)")
            print("⚠️ Falling back to in-memory storage")
            
            // Attempt in-memory fallback
            do {
                let container = try AppModelSchema.makeContainer(inMemory: true)
                bootstrapResidencyDefaults(in: container)
                return container
            } catch {
                // If even in-memory fails, this is a critical error
                fatalError("Critical: Could not create any ModelContainer (persistent or in-memory): \(error)")
            }
        }
    }()

    private static func bootstrapResidencyDefaults(in container: ModelContainer) {
        do {
            _ = try ResidencySettingsRepository(modelContext: ModelContext(container)).ensureDefaults()
        } catch {
            print("⚠️ Failed to bootstrap residency defaults: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
