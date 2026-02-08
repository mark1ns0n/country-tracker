//
//  CalendarMonthView.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI
import SwiftData

struct CalendarMonthView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentMonth: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var dayMap: [Date: DayCountryResult] = [:]
    private let calendar = Calendar.current
    private let aggregation = AggregationService()
    
    var body: some View {
        VStack(spacing: 0) {
            YearVisitedCountriesWidget()
            
            Divider()
            
            VStack(spacing: 12) {
                HStack {
                    Button(action: { moveMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(monthTitle(currentMonth))
                        .font(.title3)
                        .bold()
                    Spacer()
                    Button(action: { moveMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
            
            let days = orderedDays()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(days.indices, id: \.self) { idx in
                    let day = days[idx]
                    DayCellView(date: day, result: dayMap[day])
                }
            }
            .padding(.horizontal)
        }
    }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .stayIntervalsDidChange)) { _ in
            refresh()
        }
    }
    
    private func monthTitle(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "LLLL yyyy"
        return fmt.string(from: date).capitalized
    }
    
    private func orderedDays() -> [Date] {
        let range = monthDateRange(for: currentMonth)
        var days = DateUtils.daysInRange(range)
        days = days.map { DateUtils.startOfDay($0) }
        
        // Pad to start on correct weekday (Mon=1..Sun=7 depending on locale)
        let cal = Calendar.current
        guard let first = days.first else { return days }
        let weekday = cal.component(.weekday, from: first)
        let leading = (weekday + 6) % 7 // make Monday=0
        let paddingDates = Array(repeating: Date.distantPast, count: leading)
        return paddingDates + days
    }

    private func moveMonth(by offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newMonth
            refresh()
        }
    }

    private func monthDateRange(for date: Date) -> ClosedRange<Date> {
        let start = DateUtils.startOfDay(calendar.date(from: DateComponents(year: calendar.component(.year, from: date), month: calendar.component(.month, from: date), day: 1)) ?? date)
        let comps = DateComponents(month: 1, day: -1)
        let end = calendar.date(byAdding: comps, to: start) ?? start
        return start...DateUtils.endOfDay(end)
    }

    private func refresh() {
        let range = monthDateRange(for: currentMonth)
        let repo = StayRepository(modelContext: modelContext)
        let intervals = repo.fetchIntervals(in: range)
        print("🗓️ refresh month=", monthTitle(currentMonth), "intervals=", intervals.count)
        for i in intervals {
            print("  interval", i.countryCode, i.entryAt, i.exitAt as Any)
        }
        if intervals.isEmpty {
            print("  ⚠️ No intervals found for month range", range)
        }
        var map: [Date: DayCountryResult] = [:]
        let days = DateUtils.daysInRange(range)
        for day in days {
            let d = DateUtils.startOfDay(day)
            map[d] = aggregation.countryForDay(day, intervals: intervals)
        }
        dayMap = map
    }
}
