//
//  AggregationService.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation

/// Result of country determination for a specific day
enum DayCountryResult: Equatable {
    case single(String)           // One country for the entire day
    case mixed([String])          // Multiple countries (limited to 2 for UI)
    case unknown                  // No data for this day
    
    var displayText: String {
        switch self {
        case .single(let code):
            return code
        case .mixed(let codes):
            return codes.joined(separator: "/")
        case .unknown:
            return "—"
        }
    }
}

struct AggregationService {
    private let calendar: Calendar
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }
    
    /// Determine the country (or countries) for a specific day
    func countryForDay(_ date: Date, intervals: [StayInterval]) -> DayCountryResult {
        // Do not show data for future days
        let today = calendar.startOfDay(for: Date())
        let dayStart = DateUtils.startOfDay(date, calendar: calendar)
        if dayStart > today {
            return .unknown
        }

        let dayEnd = DateUtils.endOfDay(date, calendar: calendar)
        
        // Find all intervals that overlap with this day
        let overlappingIntervals = intervals.filter { interval in
            // For open intervals (exitAt == nil), use current date as end
            let intervalEnd = interval.exitAt ?? Date()
            return interval.entryAt <= dayEnd && intervalEnd >= dayStart
        }
        
        guard !overlappingIntervals.isEmpty else {
            return .unknown
        }
        
        // Get unique country codes
        let uniqueCountries = Set(overlappingIntervals.map { $0.countryCode })
        
        if uniqueCountries.count == 1 {
            return .single(uniqueCountries.first!)
        } else {
            // Multiple countries - limit to 2 for UI display
            let sortedCountries = Array(uniqueCountries.sorted()).prefix(2)
            return .mixed(Array(sortedCountries))
        }
    }
    
    /// Pick the country with the largest overlap for a specific day (used to avoid double-counting)
    private func dominantCountryForDay(_ date: Date, intervals: [StayInterval]) -> String? {
        let today = calendar.startOfDay(for: Date())
        let dayStart = DateUtils.startOfDay(date, calendar: calendar)
        if dayStart > today {
            return nil
        }

        let dayEnd = DateUtils.endOfDay(date, calendar: calendar)
        var durationByCountry: [String: TimeInterval] = [:]

        for interval in intervals {
            let overlapStart = max(interval.entryAt, dayStart)
            let overlapEnd = min(interval.exitAt ?? Date(), dayEnd)

            guard overlapEnd > overlapStart else { continue }
            durationByCountry[interval.countryCode, default: 0] += overlapEnd.timeIntervalSince(overlapStart)
        }

        guard !durationByCountry.isEmpty else { return nil }

        return durationByCountry
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .first?
            .key
    }

    /// Map each day in range to a single dominant country (one entry per day)
    private func dayAssignments(range: ClosedRange<Date>, intervals: [StayInterval]) -> [Date: String] {
        var assignments: [Date: String] = [:]
        let days = DateUtils.daysInRange(range, calendar: calendar)
        for day in days {
            guard let dominant = dominantCountryForDay(day, intervals: intervals) else { continue }
            let key = DateUtils.startOfDay(day, calendar: calendar)
            assignments[key] = dominant
        }
        return assignments
    }

    /// Calculate total days spent in each country within a date range (one country per day)
    func daysByCountry(range: ClosedRange<Date>, intervals: [StayInterval]) -> [String: Int] {
        var countryDays: [String: Int] = [:]
        for (_, country) in dayAssignments(range: range, intervals: intervals) {
            countryDays[country, default: 0] += 1
        }
        return countryDays
    }

    /// Count unique days with any known country in range (no double-counting for mixed days)
    func uniqueDaysWithCountry(range: ClosedRange<Date>, intervals: [StayInterval]) -> Int {
        dayAssignments(range: range, intervals: intervals).count
    }
    
    /// Get set of all visited countries in a date range
    func visitedCountries(range: ClosedRange<Date>, intervals: [StayInterval]) -> Set<String> {
        let filtered = intervals.filter { interval in
            // For open intervals (exitAt == nil), use current date as end
            let intervalEnd = interval.exitAt ?? Date()
            return interval.entryAt <= range.upperBound && intervalEnd >= range.lowerBound
        }
        
        return Set(filtered.map { $0.countryCode })
    }
}
