//
//  StringExtensions.swift
//  CountryDaysTracker
//
//  Created on 7 January 2026.
//

import Foundation

extension String {
    /// Convert ISO A2 country code to flag emoji
    func flagEmoji() -> String {
        let upper = self.uppercased()
        guard upper.count == 2 else { return "🏳️" }
        let base: UInt32 = 127397
        var result = ""
        for scalar in upper.unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                result.append(String(unicode))
            }
        }
        return result
    }
}

/// Global helper function for backward compatibility
func flagEmoji(for iso: String) -> String {
    iso.flagEmoji()
}
