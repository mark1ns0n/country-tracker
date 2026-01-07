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
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(stats: entry.stats)
        default:
            SmallWidgetView(stats: entry.stats)
        }
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    let stats: CountryYearStats
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                StatMini(icon: "🌍", value: "\(stats.countriesCount)", label: "Countries")
                StatMini(icon: "📅", value: "\(stats.totalDays)", label: "Days")
            }
            
            HStack(spacing: 8) {
                StatMini(icon: "✈️", value: "\(stats.tripsCount)", label: "Trips")
                StatMini(icon: "⭐", value: stats.topCountries.first.map { $0.code } ?? "—", label: "Top")
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Helper Views
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title3)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct StatMini: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.caption)
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
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

func yearString() -> String {
    let year = Calendar.current.component(.year, from: Date())
    return String(year)
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
        .configurationDisplayName("Travel Stats")
        .description("Your travel statistics for this year")
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
