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
    
    /// Map each day in range to all countries visited that day (a day can have multiple countries)
    private func dayCountries(range: ClosedRange<Date>, intervals: [StayInterval]) -> [Date: Set<String>] {
        var assignments: [Date: Set<String>] = [:]
        let today = calendar.startOfDay(for: Date())
        let days = DateUtils.daysInRange(range, calendar: calendar)
        
        for day in days {
            let dayStart = DateUtils.startOfDay(day, calendar: calendar)
            if dayStart > today { continue } // skip future days
            let dayEnd = DateUtils.endOfDay(day, calendar: calendar)
            
            let countriesForDay = intervals
                .filter { interval in
                    let intervalEnd = interval.exitAt ?? Date()
                    return interval.entryAt <= dayEnd && intervalEnd >= dayStart
                }
                .map { $0.countryCode }
            
            let uniqueCountries = Set(countriesForDay)
            if !uniqueCountries.isEmpty {
                assignments[dayStart] = uniqueCountries
            }
        }
        
        return assignments
    }

    /// Calculate total country-days in the range (a mixed day counts once for each country visited)
    func daysByCountry(range: ClosedRange<Date>, intervals: [StayInterval]) -> [String: Int] {
        var countryDays: [String: Int] = [:]
        for (_, countries) in dayCountries(range: range, intervals: intervals) {
            for country in countries {
                countryDays[country, default: 0] += 1
            }
        }
        return countryDays
    }

    /// Count days with at least one known country (mixed days still count once)
    func uniqueDaysWithCountry(range: ClosedRange<Date>, intervals: [StayInterval]) -> Int {
        dayCountries(range: range, intervals: intervals).count
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

    /// Map each day in range to all countries visited that day (a day can have multiple countries)
    func dayCountriesByDay(range: ClosedRange<Date>, intervals: [StayInterval]) -> [Date: Set<String>] {
        dayCountries(range: range, intervals: intervals)
    }

    /// For a target country:
    /// - increaseInDays: if user arrives there today and stays
    /// - decreaseInDays: if user does not go there from today
    func daysUntilChangeForCountry(
        targetCountry: String,
        daysInRange: [Date],
        dayCountries: [Date: Set<String>]
    ) -> (increaseInDays: Int?, decreaseInDays: Int?) {
        var firstIncrease: Int? = nil
        var firstDecrease: Int? = nil

        for (index, day) in daysInRange.enumerated() {
            let dayStart = DateUtils.startOfDay(day, calendar: calendar)
            let containsCountry = (dayCountries[dayStart] ?? []).contains(targetCountry)

            // If the dropped day is not target country, arriving to target creates net +1.
            if firstIncrease == nil && !containsCountry {
                firstIncrease = index + 1
            }

            // If the dropped day is target country and no new target day is added, net -1.
            if firstDecrease == nil && containsCountry {
                firstDecrease = index + 1
            }
            if firstIncrease != nil && firstDecrease != nil {
                break
            }
        }

        return (firstIncrease, firstDecrease)
    }
}
