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
        case .systemMedium:
            MediumWidgetView(stats: entry.stats)
        case .systemLarge:
            LargeWidgetView(stats: entry.stats)
        case .accessoryRectangular:
            AccessoryWidgetView(stats: entry.stats)
        default:
            MediumWidgetView(stats: entry.stats)
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

// MARK: - Medium Widget (2x3)
struct MediumWidgetView: View {
    let stats: CountryYearStats
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Year")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("Stats")
                        .font(.headline)
                }
                
                Spacer()
                
                Text(yearString())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 8) {
                StatCard(icon: "🌍", value: "\(stats.countriesCount)", label: "Countries")
                StatCard(icon: "📅", value: "\(stats.totalDays)", label: "Days")
                StatCard(icon: "✈️", value: "\(stats.tripsCount)", label: "Trips")
            }
            
            Divider()
            
            if !stats.topCountries.isEmpty {
                VStack(spacing: 6) {
                    HStack {
                        Text("Top 3")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    ForEach(stats.topCountries.prefix(3)) { country in
                        HStack(spacing: 8) {
                            Text(flagEmoji(for: country.code))
                                .font(.body)
                            Text(country.code)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(country.days)d")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Large Widget (2x4)
struct LargeWidgetView: View {
    let stats: CountryYearStats
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Year")
                        .font(.headline)
                    Text(yearString())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            HStack(spacing: 8) {
                StatCard(icon: "🌍", value: "\(stats.countriesCount)", label: "Countries")
                StatCard(icon: "📅", value: "\(stats.totalDays)", label: "Days")
                StatCard(icon: "✈️", value: "\(stats.tripsCount)", label: "Trips")
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Top Countries")
                    .font(.headline)
                
                ForEach(stats.topCountries.prefix(3)) { country in
                    HStack(spacing: 10) {
                        Text(flagEmoji(for: country.code))
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(country.code)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(country.days) days")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        ProgressView(value: Double(country.days), total: Double(stats.topCountries.first?.days ?? 1))
                            .tint(.blue)
                            .frame(maxWidth: 60)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Accessory Widget
struct AccessoryWidgetView: View {
    let stats: CountryYearStats
    
    var body: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Countries")
                    .font(.caption2)
                Text("\(stats.countriesCount)")
                    .font(.headline)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Days")
                    .font(.caption2)
                Text("\(stats.totalDays)")
                    .font(.headline)
            }
            
            Divider()
            
            if let top = stats.topCountries.first {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Top")
                        .font(.caption2)
                    Text(top.code)
                        .font(.headline)
                }
            }
        }
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
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

#Preview("Medium", as: .systemMedium) {
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

#Preview("Large", as: .systemLarge) {
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
