//
//  CalendarViewModel.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation
import SwiftData

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date
    @Published var dayMap: [Date: DayCountryResult] = [:]
    
    private let repository: StayRepository
    private let calendar: Calendar
    private let aggregation: AggregationService
    
    init(repository: StayRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
        self.aggregation = AggregationService(calendar: calendar)
        self.currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        
        refresh()
    }
    
    func moveMonth(by offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newMonth
            refresh()
        }
    }
    
    func refresh() {
        let monthRange = monthDateRange(for: currentMonth)
        let intervals = repository.fetchIntervals(in: monthRange)
        
        var map: [Date: DayCountryResult] = [:]
        let days = DateUtils.daysInRange(monthRange, calendar: calendar)
        for day in days {
            map[DateUtils.startOfDay(day, calendar: calendar)] = aggregation.countryForDay(day, intervals: intervals)
        }
        
        self.dayMap = map
    }
    
    func monthDateRange(for date: Date) -> ClosedRange<Date> {
        let start = DateUtils.startOfDay(calendar.date(from: DateComponents(year: calendar.component(.year, from: date), month: calendar.component(.month, from: date), day: 1)) ?? date, calendar: calendar)
        let comps = DateComponents(month: 1, day: -1)
        let end = calendar.date(byAdding: comps, to: start) ?? start
        return start...DateUtils.endOfDay(end, calendar: calendar)
    }
}
