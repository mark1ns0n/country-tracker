//
//  YearStatsWidget.swift
//  CountryDaysTracker
//
//  Created on 18 December 2025.
//

import SwiftUI
import SwiftData

struct YearStatsWidget: View {
    @Environment(\.modelContext) private var modelContext
    @State private var stats: YearStats?
    @State private var topCountries: [(code: String, days: Int)] = []
    
    let repository: StayRepository
    
    init(repository: StayRepository) {
        self.repository = repository
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Year")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(currentYearString())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            // Main metrics
            HStack(spacing: 12) {
                YearStatCard(
                    icon: "🌍",
                    title: "Countries",
                    value: "\(stats?.countriesCount ?? 0)"
                )
                
                YearStatCard(
                    icon: "📅",
                    title: "Days Away",
                    value: "\(stats?.totalDays ?? 0)"
                )
                
                YearStatCard(
                    icon: "✈️",
                    title: "Trips",
                    value: "\(stats?.tripsCount ?? 0)"
                )
            }
            .padding(.horizontal)
            
            // Top countries
            if !topCountries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Countries")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 6) {
                        ForEach(topCountries.prefix(3), id: \.code) { item in
                            HStack(spacing: 12) {
                                Text(flagEmoji(for: item.code))
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.code)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("\(item.days) days")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                ProgressView(value: Double(item.days), total: Double(topCountries.first?.days ?? 1))
                                    .tint(.blue)
                                    .frame(maxWidth: 60)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .onAppear { refreshStats() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("stayIntervalsDidChange"))) { _ in
            refreshStats()
        }
    }
    
    private func refreshStats() {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        
        // Get range for current year
        let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? now
        let yearEnd = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? now
        let range = yearStart...yearEnd
        
        // Fetch intervals
        let intervals = repository.fetchIntervals(in: range)
        
        // Calculate stats
        let daysCounts = AggregationService().daysByCountry(range: range, intervals: intervals)
        let countries = AggregationService().visitedCountries(range: range, intervals: intervals)
        
        let totalDays = daysCounts.values.reduce(0, +)
        let tripsCount = calculateTripsCount(intervals: intervals)
        
        stats = YearStats(
            countriesCount: countries.count,
            totalDays: totalDays,
            tripsCount: tripsCount
        )
        
        topCountries = daysCounts
            .map { ($0.key, $0.value) }
            .sorted { $0.days > $1.days }
        
        // Save to widget
        let countryDataArray = topCountries
            .prefix(3)
            .map { CountryData(code: $0.code, days: $0.days) }
        
        let yearStats = CountryYearStats(
            countriesCount: countries.count,
            totalDays: totalDays,
            tripsCount: tripsCount,
            topCountries: countryDataArray,
            lastUpdated: Date()
        )
        
        WidgetDataService.shared.saveStats(yearStats)
    }
    
    private func calculateTripsCount(intervals: [StayInterval]) -> Int {
        // A trip is a continuous stay or a gap of less than a certain threshold
        // For simplicity, count intervals with exitAt set as completed trips
        return intervals.filter { $0.exitAt != nil }.count
    }
    
    private func flagEmoji(for iso: String) -> String {
        let upper = iso.uppercased()
        guard upper.count == 2 else { return "🏳️" }
        let base: UInt32 = 127397
        var s = ""
        for scalar in upper.unicodeScalars {
            if let u = UnicodeScalar(base + scalar.value) { s.append(String(u)) }
        }
        return s
    }
    
    private func currentYearString() -> String {
        let year = Calendar.current.component(.year, from: Date())
        return String(year)
    }
}

struct YearStatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 28))
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct YearStats {
    let countriesCount: Int
    let totalDays: Int
    let tripsCount: Int
}

#Preview {
    let schema = Schema([
        StayInterval.self,
        LocationEventLog.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    
    return YearStatsWidget(repository: StayRepository(modelContext: container.mainContext))
        .modelContainer(container)
}
