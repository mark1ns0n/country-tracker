//
//  ResidencyProfile.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation
import SwiftData

@Model
final class ResidencyProfile {
    var id: UUID
    var homeCountryCode: String
    var activeRuleIdentifier: String?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        homeCountryCode: String = "RU",
        activeRuleIdentifier: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.homeCountryCode = homeCountryCode.uppercased()
        self.activeRuleIdentifier = activeRuleIdentifier
        self.updatedAt = updatedAt
    }
}
