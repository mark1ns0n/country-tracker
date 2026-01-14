//
//  CalendarAndMapView.swift
//  CountryDaysTracker
//
//  Created on 15 December 2025.
//

import SwiftUI
import MapKit
import SwiftData

struct CalendarAndMapView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentMonth: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var dayMap: [Date: DayCountryResult] = [:]
    @State private var selectedDay: Date? = nil
    @State private var showDetails: Bool = false
    @State private var overlays: [MKOverlay] = []
    @State private var highlightedCountries: Set<String> = []
    
    private let calendar = Calendar.current
    private let aggregation = AggregationService()
    
    var body: some View {
        VStack(spacing: 0) {
            // Calendar section - scrollable
            ScrollView {
                VStack(spacing: 12) {
                    // Calendar header
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
                    
                    // Calendar grid
                    let days = orderedDays()
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
                    
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(days.indices, id: \.self) { idx in
                            let day = days[idx]
                            DayCellView(date: day, result: dayMap[day])
                                .onTapGesture {
                                    guard day != Date.distantPast else { return }
                                    selectedDay = day
                                    showDetails = true
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // Map - takes all remaining space
            MapWebView(visitedCountries: highlightedCountries)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        
        let cal = Calendar.current
        guard let first = days.first else { return days }
        let weekday = cal.component(.weekday, from: first)
        let leading = (weekday + 6) % 7
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
        
        // Update calendar
        var map: [Date: DayCountryResult] = [:]
        let days = DateUtils.daysInRange(range)
        for day in days {
            let d = DateUtils.startOfDay(day)
            map[d] = aggregation.countryForDay(day, intervals: intervals)
        }
        dayMap = map
        
        // Update map with last 30 days
        let last30Range = Date().addingTimeInterval(-30*24*3600)...Date()
        let last30Intervals = repo.fetchIntervals(in: last30Range)
        let visited = aggregation.visitedCountries(range: last30Range, intervals: last30Intervals)
        
        let geometry = CountryGeometryStore()
        var newOverlays: [MKOverlay] = []
        for code in visited {
            if let polys = geometry.polygonsByISO[code] {
                newOverlays.append(contentsOf: polys)
            }
        }
        overlays = newOverlays
        highlightedCountries = visited
    }
}

#Preview {
    CalendarAndMapView()
}
