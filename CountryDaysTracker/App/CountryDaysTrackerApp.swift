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
        let schema = Schema([
            StayInterval.self,
            LocationEventLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Log error and try in-memory fallback
            print("❌ Failed to create persistent ModelContainer: \(error)")
            print("⚠️ Falling back to in-memory storage")
            
            // Attempt in-memory fallback
            do {
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                // If even in-memory fails, this is a critical error
                fatalError("Critical: Could not create any ModelContainer (persistent or in-memory): \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
