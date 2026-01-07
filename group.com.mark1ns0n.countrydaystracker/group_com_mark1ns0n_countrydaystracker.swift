//
//  group_com_mark1ns0n_countrydaystracker.swift
//  group.com.mark1ns0n.countrydaystracker
//
//  Updated to show top 3 countries for the year.
//

import WidgetKit
import SwiftUI
import Foundation

struct CountryTrackerEntry: TimelineEntry {
    let date: Date
    let stats: CountryYearStats
}

struct Provider: AppIntentTimelineProvider {
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
        let stats = WidgetDataService.shared.loadStats() ?? placeholder(in: context).stats
        return CountryTrackerEntry(date: Date(), stats: stats)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<CountryTrackerEntry> {
        let stats = WidgetDataService.shared.loadStats() ?? placeholder(in: context).stats
        let entry = CountryTrackerEntry(date: Date(), stats: stats)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct group_com_mark1ns0n_countrydaystrackerEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        SmallWidgetView(stats: entry.stats)
    }
}

struct group_com_mark1ns0n_countrydaystracker: Widget {
    let kind: String = "group_com_mark1ns0n_countrydaystracker"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            group_com_mark1ns0n_countrydaystrackerEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Top 3 Countries")
        .description("Top 3 countries from the last 365 days")
    }
}

// MARK: - Views
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

#Preview(as: .systemSmall) {
    group_com_mark1ns0n_countrydaystracker()
} timeline: {
    CountryTrackerEntry(date: .now, stats: CountryYearStats(countriesCount: 3, totalDays: 30, tripsCount: 2, topCountries: [CountryData(code: "FR", days: 12), CountryData(code: "IT", days: 10), CountryData(code: "ES", days: 8)], lastUpdated: .now))
}
