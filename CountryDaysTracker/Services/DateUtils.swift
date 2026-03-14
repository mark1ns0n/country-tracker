//
//  DateUtils.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation

struct DateUtils {
    /// Returns the start of the day (00:00:00) for the given date
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        return calendar.startOfDay(for: date)
    }
    
    /// Returns the end of the day (23:59:59.999) for the given date
    static func endOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfDay(date, calendar: calendar)) ?? date
    }
    
    /// Returns array of dates for each day in the given range
    static func daysInRange(_ range: ClosedRange<Date>, calendar: Calendar = .current) -> [Date] {
        let startDay = startOfDay(range.lowerBound, calendar: calendar)
        let endDay = startOfDay(range.upperBound, calendar: calendar)
        
        var days: [Date] = []
        var currentDay = startDay
        
        while currentDay <= endDay {
            days.append(currentDay)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                break
            }
            currentDay = nextDay
        }
        
        return days
    }

    /// Returns a rolling 365-day range that includes today.
    static func last365DaysRange(endingAt date: Date = Date(), calendar: Calendar = .current) -> ClosedRange<Date> {
        let start = calendar.date(byAdding: .day, value: -364, to: date) ?? date
        return startOfDay(start, calendar: calendar)...endOfDay(date, calendar: calendar)
    }
}
