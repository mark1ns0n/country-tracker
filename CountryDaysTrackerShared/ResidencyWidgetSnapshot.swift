//
//  ResidencyWidgetSnapshot.swift
//  CountryDaysTracker
//
//  Created on 15 March 2026.
//

import Foundation

struct ResidencyWidgetSnapshot: Codable, Equatable {
    let homeCountryCode: String
    let daysUsed: Int
    let daysRemaining: Int
    let nextSafeEntryDate: Date?
    let safeUntilDate: Date?
    let lastUpdated: Date
}

enum ResidencyWidgetStore {
    static let suiteName = "group.com.mark1ns0n.countrydaystracker"
    static let snapshotKey = "residencyWidget_v1"
    static let widgetKind = "CountryTrackerWidget"
}
