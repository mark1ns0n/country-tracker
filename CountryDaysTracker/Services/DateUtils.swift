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
    
    /// Returns the number of days between two dates (inclusive)
    static func dayCount(from startDate: Date, to endDate: Date, calendar: Calendar = .current) -> Int {
        let start = startOfDay(startDate, calendar: calendar)
        let end = startOfDay(endDate, calendar: calendar)
        
        let components = calendar.dateComponents([.day], from: start, to: end)
        return (components.day ?? 0) + 1 // +1 to include both start and end day
    }
}
