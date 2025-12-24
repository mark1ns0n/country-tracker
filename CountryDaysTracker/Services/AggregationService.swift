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
            let intervalEnd = interval.exitAt ?? Date.distantFuture
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
    
    /// Calculate total days spent in each country within a date range
    func daysByCountry(range: ClosedRange<Date>, intervals: [StayInterval]) -> [String: Int] {
        var countryDays: [String: Set<Date>] = [:]
        
        let days = DateUtils.daysInRange(range, calendar: calendar)
        
        for day in days {
            let result = countryForDay(day, intervals: intervals)
            
            switch result {
            case .single(let code):
                countryDays[code, default: []].insert(DateUtils.startOfDay(day, calendar: calendar))
            case .mixed(let codes):
                // For mixed days, count them for all countries involved
                for code in codes {
                    countryDays[code, default: []].insert(DateUtils.startOfDay(day, calendar: calendar))
                }
            case .unknown:
                break
            }
        }
        
        // Convert sets to counts
        return countryDays.mapValues { $0.count }
    }
    
    /// Get set of all visited countries in a date range
    func visitedCountries(range: ClosedRange<Date>, intervals: [StayInterval]) -> Set<String> {
        let filtered = intervals.filter { interval in
            let intervalEnd = interval.exitAt ?? Date.distantFuture
            return interval.entryAt <= range.upperBound && intervalEnd >= range.lowerBound
        }
        
        return Set(filtered.map { $0.countryCode })
    }
}
