//
//  StayEngine.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation

/// Engine responsible for managing country stay intervals
@MainActor
class StayEngine {
    private let repository: StayRepository
    
    /// Optional callback for confirming country changes (anti-flapping)
    var confirmCountryChange: ((String, Date) async -> Bool)?
    
    init(repository: StayRepository) {
        self.repository = repository
    }
    
    /// Process a country update from location services
    /// - Parameters:
    ///   - countryCode: ISO A2 country code
    ///   - at: Timestamp of the update
    ///   - source: Source of the update (e.g., "significant-location", "visit")
    ///   - confidence: Confidence level of the location (0.0 to 1.0)
    func processCountryUpdate(
        countryCode: String,
        at: Date,
        source: String,
        confidence: Double
    ) async {
        // Fetch the currently open interval
        guard let openInterval = repository.fetchOpenInterval() else {
            // No open interval - create the first one
            repository.insertInterval(
                countryCode: countryCode,
                entryAt: at,
                source: source,
                confidence: confidence
            )
            print("✅ Created first interval for country: \(countryCode)")
            return
        }
        
        // Check if it's the same country
        if openInterval.countryCode == countryCode {
            // Same country - just update the timestamp
            openInterval.updatedAt = Date()
            print("✏️ Updated existing interval for country: \(countryCode)")
            return
        }
        
        // Different country - check if we should confirm the change
        if let confirmCallback = confirmCountryChange {
            let confirmed = await confirmCallback(countryCode, at)
            if !confirmed {
                print("⏸️ Country change not confirmed, skipping: \(countryCode)")
                return
            }
        }
        
        // Close the current interval and open a new one
        repository.closeInterval(id: openInterval.id, exitAt: at)
        repository.insertInterval(
            countryCode: countryCode,
            entryAt: at,
            source: source,
            confidence: confidence
        )
        
        print("🔄 Switched from \(openInterval.countryCode) to \(countryCode)")
    }
}
