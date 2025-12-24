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

struct group_com_mark1ns0n_countrydaystracker: Widget {
    let kind: String = "group_com_mark1ns0n_countrydaystracker"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            group_com_mark1ns0n_countrydaystrackerEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
        .configurationDisplayName("Travel Stats")
        .description("Your travel statistics for the last 12 months")
    }
}

// MARK: - Views
struct SmallWidgetView: View {
    let stats: CountryYearStats
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last year:")
                .font(.system(size: 21, weight: .semibold))
            
            if stats.topCountries.isEmpty {
                Text("No trips yet")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            } else {
                ForEach(stats.topCountries.prefix(2)) { country in
                    HStack(spacing: 10) {
                        Text(flagEmoji(for: country.code))
                            .font(.system(size: 20))
                        Text(countryName(for: country.code))
                            .font(.system(size: 14))
                            .lineLimit(1)
                        Spacer()
                        Text("\(country.days)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(2)
    }
}

struct MediumWidgetView: View {
    let stats: CountryYearStats
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last 12 Months").font(.caption2).foregroundColor(.gray)
                    Text("Stats").font(.headline)
                }
                Spacer()
                Text(lastYearRangeString()).font(.caption).foregroundColor(.gray)
            }
            HStack(spacing: 8) {
                StatCard(icon: "🌍", value: "\(stats.countriesCount)", label: "Countries")
                StatCard(icon: "📅", value: "\(stats.totalDays)", label: "Days")
                StatCard(icon: "✈️", value: "\(stats.tripsCount)", label: "Trips")
            }
            Divider()
            if !stats.topCountries.isEmpty {
                VStack(spacing: 6) {
                    HStack { Text("Top 3").font(.caption).fontWeight(.semibold); Spacer() }
                    ForEach(stats.topCountries.prefix(3)) { country in
                        HStack(spacing: 8) {
                            Text(flagEmoji(for: country.code)).font(.body)
                            Text(country.code).font(.caption).fontWeight(.medium)
                            Spacer()
                            Text("\(country.days)d").font(.caption2).foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding(12)
    }
}

struct LargeWidgetView: View {
    let stats: CountryYearStats
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last 12 Months").font(.headline)
                    Text(lastYearRangeString()).font(.caption).foregroundColor(.gray)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                StatCard(icon: "🌍", value: "\(stats.countriesCount)", label: "Countries")
                StatCard(icon: "📅", value: "\(stats.totalDays)", label: "Days")
                StatCard(icon: "✈️", value: "\(stats.tripsCount)", label: "Trips")
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Top Countries").font(.headline)
                ForEach(stats.topCountries.prefix(3)) { country in
                    HStack(spacing: 10) {
                        Text(flagEmoji(for: country.code)).font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(country.code).font(.subheadline).fontWeight(.semibold)
                            Text("\(country.days) days").font(.caption).foregroundColor(.gray)
                        }
                        Spacer()
                        ProgressView(value: Double(country.days), total: Double(stats.topCountries.first?.days ?? 1))
                            .tint(.blue)
                            .frame(maxWidth: 60)
                    }
                    .padding(8)
                }
            }
            Spacer()
        }
        .padding(12)
    }
}

struct AccessoryWidgetView: View {
    let stats: CountryYearStats
    var body: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Countries").font(.caption2)
                Text("\(stats.countriesCount)").font(.headline)
            }
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                Text("Days").font(.caption2)
                Text("\(stats.totalDays)").font(.headline)
            }
            Divider()
            if let top = stats.topCountries.first {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Top").font(.caption2)
                    Text(top.code).font(.headline)
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
            Text(icon).font(.title3)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundColor(.gray).lineLimit(1)
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
            Text(icon).font(.caption)
            Text(value).font(.caption).fontWeight(.bold)
            Text(label).font(.system(size: 9)).foregroundColor(.gray).lineLimit(1)
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

func countryName(for iso: String) -> String {
    let upper = iso.uppercased()
    return Locale.current.localizedString(forRegionCode: upper) ?? upper
}

func lastYearRangeString() -> String {
    let calendar = Calendar.current
    let now = Date()
    let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM yyyy"
    return "\(formatter.string(from: start)) - \(formatter.string(from: now))"
}

#Preview(as: .systemSmall) {
    group_com_mark1ns0n_countrydaystracker()
} timeline: {
    CountryTrackerEntry(date: .now, stats: CountryYearStats(countriesCount: 3, totalDays: 30, tripsCount: 2, topCountries: [CountryData(code: "FR", days: 12), CountryData(code: "IT", days: 10), CountryData(code: "ES", days: 8)], lastUpdated: .now))
}
