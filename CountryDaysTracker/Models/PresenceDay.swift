//
//  PresenceDay.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation
import SwiftData

@Model
final class PresenceDay {
    static let derivedSource = "derived.stayInterval"

    var id: UUID
    var date: Date
    var countryCode: String
    var source: String
    var isManualOverride: Bool
    var notes: String?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        countryCode: String,
        source: String,
        isManualOverride: Bool = false,
        notes: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.countryCode = countryCode.uppercased()
        self.source = source
        self.isManualOverride = isManualOverride
        self.notes = notes
        self.updatedAt = updatedAt
    }
}
