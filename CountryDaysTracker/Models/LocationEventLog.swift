//
//  LocationEventLog.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation
import SwiftData

@Model
final class LocationEventLog {
    var id: UUID
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var source: String
    var countryCodeCandidate: String?
    var accepted: Bool
    var note: String?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double,
        source: String,
        countryCodeCandidate: String? = nil,
        accepted: Bool = false,
        note: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.source = source
        self.countryCodeCandidate = countryCodeCandidate
        self.accepted = accepted
        self.note = note
    }
}
