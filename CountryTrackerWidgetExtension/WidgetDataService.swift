import Foundation

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
    static let intervalsKey = "yearStatsWidgetIntervals_v1"
}

struct WidgetStayInterval: Codable {
    let countryCode: String
    let entryAt: Date
    let exitAt: Date?
}

final class WidgetDataService {
    static let shared = WidgetDataService()
    
    private init() {}
    
    func loadStats() -> CountryYearStats? {
        let defaults = UserDefaults(suiteName: WidgetStatsDefaults.suiteName)
        let decoder = JSONDecoder()
        
        // Prefer recalculating from raw intervals so the widget stays fresh even if the app isn't opened daily
        if let intervalsData = defaults?.data(forKey: WidgetStatsDefaults.intervalsKey),
           let intervals = try? decoder.decode([WidgetStayInterval].self, from: intervalsData),
           let recomputed = recomputeStats(from: intervals) {
            return recomputed
        }
        
        guard let data = defaults?.data(forKey: WidgetStatsDefaults.statsKey) else { return nil }
        
        do {
            return try decoder.decode(CountryYearStats.self, from: data)
        } catch {
            print("Failed to decode widget stats: \(error)")
            return nil
        }
    }
}

private extension String {
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

func flagEmoji(for iso: String) -> String {
    iso.flagEmoji()
}

// MARK: - Local aggregation helpers (mirrors app logic)
private extension WidgetDataService {
    func recomputeStats(from intervals: [WidgetStayInterval]) -> CountryYearStats? {
        let range = lastYearRange()
        let counts = daysByCountry(range: range, intervals: intervals)
        let countries = visitedCountries(range: range, intervals: intervals)
        let totalDays = uniqueDaysWithCountry(range: range, intervals: intervals)
        let tripsCount = intervals.filter { $0.exitAt != nil }.count
        
        let topCountries = counts
            .map { CountryData(code: $0.key, days: $0.value) }
            .sorted { lhs, rhs in
                lhs.days == rhs.days ? lhs.code < rhs.code : lhs.days > rhs.days
            }
        
        return CountryYearStats(
            countriesCount: countries.count,
            totalDays: totalDays,
            tripsCount: tripsCount,
            topCountries: topCountries,
            lastUpdated: Date()
        )
    }
    
    func lastYearRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(byAdding: .day, value: -364, to: now) ?? now
        let rangeStart = startOfDay(start, calendar: calendar)
        let rangeEnd = endOfDay(now, calendar: calendar)
        return rangeStart...rangeEnd
    }
    
    func startOfDay(_ date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }
    
    func endOfDay(_ date: Date, calendar: Calendar) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfDay(date, calendar: calendar)) ?? date
    }
    
    func daysInRange(_ range: ClosedRange<Date>, calendar: Calendar) -> [Date] {
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
    
    func dayCountries(range: ClosedRange<Date>, intervals: [WidgetStayInterval], calendar: Calendar) -> [Date: Set<String>] {
        var assignments: [Date: Set<String>] = [:]
        let today = calendar.startOfDay(for: Date())
        
        for day in daysInRange(range, calendar: calendar) {
            let dayStart = startOfDay(day, calendar: calendar)
            if dayStart > today { continue }
            let dayEnd = endOfDay(day, calendar: calendar)
            
            let countries = intervals
                .filter { interval in
                    let intervalEnd = interval.exitAt ?? Date()
                    return interval.entryAt <= dayEnd && intervalEnd >= dayStart
                }
                .map { $0.countryCode }
            
            let unique = Set(countries)
            if !unique.isEmpty {
                assignments[dayStart] = unique
            }
        }
        
        return assignments
    }
    
    func daysByCountry(range: ClosedRange<Date>, intervals: [WidgetStayInterval]) -> [String: Int] {
        var result: [String: Int] = [:]
        let calendar = Calendar.current
        for (_, countries) in dayCountries(range: range, intervals: intervals, calendar: calendar) {
            for country in countries {
                result[country, default: 0] += 1
            }
        }
        return result
    }
    
    func uniqueDaysWithCountry(range: ClosedRange<Date>, intervals: [WidgetStayInterval]) -> Int {
        let calendar = Calendar.current
        return dayCountries(range: range, intervals: intervals, calendar: calendar).count
    }
    
    func visitedCountries(range: ClosedRange<Date>, intervals: [WidgetStayInterval]) -> Set<String> {
        let filtered = intervals.filter { interval in
            let end = interval.exitAt ?? Date()
            return interval.entryAt <= range.upperBound && end >= range.lowerBound
        }
        return Set(filtered.map { $0.countryCode })
    }
}
