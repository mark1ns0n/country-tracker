//
//  CountryTrackerWidget.swift
//  CountryTrackerWidget
//
//  Created on 18 December 2025.
//

import WidgetKit
import SwiftUI

private enum WidgetConstants {
    static let kind = "CountryTrackerWidget"
}

struct CountryTrackerWidgetProvider: TimelineProvider {
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
    
    func getSnapshot(in context: Context, completion: @escaping (CountryTrackerEntry) -> Void) {
        let stats = WidgetDataService.shared.loadStats() ?? placeholder(in: context).stats
        completion(CountryTrackerEntry(date: Date(), stats: stats))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CountryTrackerEntry>) -> Void) {
        let stats = WidgetDataService.shared.loadStats() ?? placeholder(in: context).stats
        let entry = CountryTrackerEntry(date: Date(), stats: stats)
        
        // Update every hour - use safe date calculation
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
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
    }
}

// MARK: - Widget Definition
struct CountryTrackerWidget: Widget {
    let kind: String = WidgetConstants.kind
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: CountryTrackerWidgetProvider()
        ) { entry in
            CountryTrackerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Top 3 Countries")
        .description("Top 3 countries from the last 365 days")
    }
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
