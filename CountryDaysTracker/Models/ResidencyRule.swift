//
//  ResidencyRule.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation
import SwiftData

@Model
final class ResidencyRule {
    var id: UUID
    var identifier: String
    var jurisdictionCode: String
    var windowKind: String
    var windowLengthDays: Int
    var thresholdDays: Int
    var safeLimitDays: Int
    var isEnabled: Bool
    var title: String

    init(
        id: UUID = UUID(),
        identifier: String,
        jurisdictionCode: String,
        windowKind: String = "rollingDays",
        windowLengthDays: Int,
        thresholdDays: Int,
        safeLimitDays: Int,
        isEnabled: Bool = true,
        title: String
    ) {
        self.id = id
        self.identifier = identifier
        self.jurisdictionCode = jurisdictionCode.uppercased()
        self.windowKind = windowKind
        self.windowLengthDays = windowLengthDays
        self.thresholdDays = thresholdDays
        self.safeLimitDays = safeLimitDays
        self.isEnabled = isEnabled
        self.title = title
    }
}
