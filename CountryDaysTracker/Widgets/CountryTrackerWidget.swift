//
//  CountryTrackerWidget.swift
//  CountryTrackerWidget
//
//  Created on 18 December 2025.
//

import WidgetKit
import SwiftUI

struct CountryTrackerWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CountryTrackerEntry {
        CountryTrackerEntry(
            date: Date(),
            stats: CountryYearStats(
                countriesCount: 12,
                totalDays: 45,
                tripsCount: 5,
                topCountries: [
                    CountryData(code: "FR", days: 15),
                    CountryData(code: "IT", days: 12),
                    CountryData(code: "ES", days: 10)
                ],
                lastUpdated: Date()
            )
        )
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> CountryTrackerEntry {
        placeholder(in: context)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<CountryTrackerEntry> {
        let stats = WidgetDataService.shared.loadStats() ?? placeholder(in: context).stats
        let entry = CountryTrackerEntry(date: Date(), stats: stats)
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        []
    }
}

struct CountryTrackerEntry: TimelineEntry {
    let date: Date
    let stats: CountryYearStats
}

struct CountryTrackerWidgetEntryView: View {
    var entry: CountryTrackerWidgetProvider.Entry
    
    var body: some View {
        SmallWidgetView(stats: entry.stats)
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    let stats: CountryYearStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Top 3 • 365d")
                .font(.caption2)
                .foregroundColor(.gray)
            if stats.topCountries.isEmpty {
                Text("No data")
                    .font(.caption2)
                    .foregroundColor(.gray)
            } else {
                ForEach(stats.topCountries.prefix(3)) { country in
                    HStack(spacing: 6) {
                        Text(flagEmoji(for: country.code))
                            .font(.caption)
                        Text(country.code)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(country.days)d")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
    }
}

// MARK: - Helper Views
// MARK: - Helpers
func flagEmoji(for iso: String) -> String {
    let upper = iso.uppercased()
    guard upper.count == 2 else { return "🏳️" }
    let base: UInt32 = 127397
    var s = ""
    for scalar in upper.unicodeScalars {
        if let u = UnicodeScalar(base + scalar.value) { s.append(String(u)) }
    }
    return s
}

// MARK: - Widget Definition
struct CountryTrackerWidget: Widget {
    let kind: String = "CountryTrackerWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: CountryTrackerWidgetProvider()
        ) { entry in
            CountryTrackerWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Top 3 Countries")
        .description("Top 3 countries from the last 365 days")
    }
}

// MARK: - Configuration Intent
struct ConfigurationAppIntent: AppIntent, Identifiable, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Travel Stats Widget"
    static var description = IntentDescription("Shows your year travel statistics")
    
    var id: String = UUID().uuidString
}

#Preview("Small", as: .systemSmall) {
    CountryTrackerWidget()
} timeline: {
    CountryTrackerEntry(
        date: Date(),
        stats: CountryYearStats(
            countriesCount: 12,
            totalDays: 45,
            tripsCount: 5,
            topCountries: [
                CountryData(code: "FR", days: 15),
                CountryData(code: "IT", days: 12),
                CountryData(code: "ES", days: 10)
            ],
            lastUpdated: Date()
        )
    )
}
