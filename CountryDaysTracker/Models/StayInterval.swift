//
//  StayInterval.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation
import SwiftData

@Model
final class StayInterval {
    var id: UUID
    var countryCode: String  // ISO A2 code
    var entryAt: Date
    var exitAt: Date?
    var source: String
    var confidence: Double
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        countryCode: String,
        entryAt: Date,
        exitAt: Date? = nil,
        source: String,
        confidence: Double,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.countryCode = countryCode
        self.entryAt = entryAt
        self.exitAt = exitAt
        self.source = source
        self.confidence = confidence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
