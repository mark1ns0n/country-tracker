//
//  StayRepository.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation
import SwiftData
import WidgetKit

extension Notification.Name {
    /// Broadcast when stay intervals are inserted or closed
    static let stayIntervalsDidChange = Notification.Name("stayIntervalsDidChange")
}

struct CountryYearStats: Codable {
    let countriesCount: Int
    let totalDays: Int
    let tripsCount: Int
    let topCountries: [CountryData]
    let lastUpdated: Date
}

struct CountryData: Codable, Identifiable {
    let id: String
    let code: String
    let days: Int
    
    enum CodingKeys: String, CodingKey {
        case code
        case days
    }
    
    init(code: String, days: Int) {
        self.id = code
        self.code = code
        self.days = days
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        days = try container.decode(Int.self, forKey: .days)
        id = code
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(days, forKey: .days)
    }
}

private enum WidgetStatsDefaults {
    static let suiteName = "group.com.mark1ns0n.countrydaystracker"
    static let statsKey = "yearStatsWidget_v2"
}

private actor WidgetRefreshCoordinator {
    private var refreshTask: Task<Void, Never>?
    
    func scheduleRefresh(_ operation: @escaping @Sendable () -> Void) {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms debounce
            guard !Task.isCancelled else { return }
            operation()
        }
    }
}

@MainActor
class StayRepository {
    private let modelContext: ModelContext
    private let widgetRefreshCoordinator = WidgetRefreshCoordinator()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - StayInterval Methods
    
    /// Fetch the currently open interval (where exitAt is nil)
    func fetchOpenInterval() -> StayInterval? {
        let descriptor = FetchDescriptor<StayInterval>(
            predicate: #Predicate { $0.exitAt == nil },
            sortBy: [SortDescriptor(\.entryAt, order: .reverse)]
        )
        
        do {
            let intervals = try modelContext.fetch(descriptor)
            return intervals.first
        } catch {
            print("Error fetching open interval: \(error)")
            return nil
        }
    }
    
    /// Fetch all intervals within a date range
    func fetchIntervals(in range: ClosedRange<Date>) -> [StayInterval] {
        let startDate = range.lowerBound
        let endDate = range.upperBound
        
        let descriptor = FetchDescriptor<StayInterval>(
            predicate: #Predicate { interval in
                (interval.entryAt <= endDate) && ((interval.exitAt ?? endDate) >= startDate)
            },
            sortBy: [SortDescriptor(\.entryAt, order: .forward)]
        )
        
        do {
            let result = try modelContext.fetch(descriptor)
            print("📦 fetchIntervals range=\(startDate)→\(endDate) count=\(result.count)")
            return result
        } catch {
            print("Error fetching intervals in range: \(error)")
            return []
        }
    }
    
    /// Insert a new interval
    func insertInterval(
        countryCode: String,
        entryAt: Date,
        exitAt: Date? = nil,
        source: String,
        confidence: Double
    ) {
        let interval = StayInterval(
            countryCode: countryCode,
            entryAt: entryAt,
            exitAt: exitAt,
            source: source,
            confidence: confidence
        )
        
        modelContext.insert(interval)
        
        do {
            try modelContext.save()
            Task {
                await widgetRefreshCoordinator.scheduleRefresh { [weak self] in
                    Task { @MainActor in
                        self?.refreshWidgetStatsForLastYear()
                    }
                }
            }
            NotificationCenter.default.post(name: .stayIntervalsDidChange, object: nil)
        } catch {
            print("Error inserting interval: \(error)")
        }
    }
    
    /// Close an interval by setting its exitAt date
    func closeInterval(id: UUID, exitAt: Date) {
        let descriptor = FetchDescriptor<StayInterval>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let intervals = try modelContext.fetch(descriptor)
            if let interval = intervals.first {
                interval.exitAt = exitAt
                interval.updatedAt = Date()
                try modelContext.save()
                Task {
                    await widgetRefreshCoordinator.scheduleRefresh { [weak self] in
                        Task { @MainActor in
                            self?.refreshWidgetStatsForLastYear()
                        }
                    }
                }
                NotificationCenter.default.post(name: .stayIntervalsDidChange, object: nil)
            }
        } catch {
            print("Error closing interval: \(error)")
        }
    }
    
    // MARK: - LocationEventLog Methods
    
    /// Append a new location event log
    func appendLog(
        latitude: Double,
        longitude: Double,
        source: String,
        countryCodeCandidate: String? = nil,
        accepted: Bool = false,
        note: String? = nil
    ) {
        let log = LocationEventLog(
            latitude: latitude,
            longitude: longitude,
            source: source,
            countryCodeCandidate: countryCodeCandidate,
            accepted: accepted,
            note: note
        )
        
        modelContext.insert(log)
        
        do {
            try modelContext.save()
        } catch {
            print("Error appending log: \(error)")
        }
    }
    
    /// Fetch recent logs (for debugging)
    func fetchRecentLogs(limit: Int = 200) -> [LocationEventLog] {
        let descriptor = FetchDescriptor<LocationEventLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let logs = try modelContext.fetch(descriptor)
            return Array(logs.prefix(limit))
        } catch {
            print("Error fetching logs: \(error)")
            return []
        }
    }
    
    func refreshWidgetStatsForLastYear() {
        let range = lastYearRange()
        let intervals = fetchIntervals(in: range)
        let aggregation = AggregationService()
        
        let daysCounts = aggregation.daysByCountry(range: range, intervals: intervals)
        let countries = aggregation.visitedCountries(range: range, intervals: intervals)
        
        let totalDays = aggregation.uniqueDaysWithCountry(range: range, intervals: intervals)
        let tripsCount = intervals.filter { $0.exitAt != nil }.count
        
        let topCountries = daysCounts
            .map { CountryData(code: $0.key, days: $0.value) }
            .sorted { $0.days > $1.days }
        
        let stats = CountryYearStats(
            countriesCount: countries.count,
            totalDays: totalDays,
            tripsCount: tripsCount,
            topCountries: topCountries,
            lastUpdated: Date()
        )
        
        saveWidgetStats(stats)
    }
    
    private func lastYearRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(byAdding: .day, value: -364, to: now) ?? now
        let rangeStart = DateUtils.startOfDay(start, calendar: calendar)
        let rangeEnd = DateUtils.endOfDay(now, calendar: calendar)
        return rangeStart...rangeEnd
    }
    
    private func saveWidgetStats(_ stats: CountryYearStats) {
        do {
            let data = try JSONEncoder().encode(stats)
            UserDefaults(suiteName: WidgetStatsDefaults.suiteName)?
                .set(data, forKey: WidgetStatsDefaults.statsKey)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save widget stats: \(error)")
        }
    }
}
