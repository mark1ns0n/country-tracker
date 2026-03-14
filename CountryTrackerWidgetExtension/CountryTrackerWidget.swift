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
            snapshot: ResidencyWidgetSnapshot(
                homeCountryCode: "RU",
                daysUsed: 100,
                daysRemaining: 82,
                nextSafeEntryDate: Date(),
                safeUntilDate: Calendar.current.date(byAdding: .day, value: 82, to: Date()),
                lastUpdated: Date()
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CountryTrackerEntry) -> Void) {
        let snapshot = WidgetDataService.shared.loadSnapshot() ?? placeholder(in: context).snapshot
        completion(CountryTrackerEntry(date: Date(), snapshot: snapshot))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CountryTrackerEntry>) -> Void) {
        let snapshot = WidgetDataService.shared.loadSnapshot() ?? placeholder(in: context).snapshot
        let entry = CountryTrackerEntry(date: Date(), snapshot: snapshot)
        
        // Update every hour - use safe date calculation
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct CountryTrackerEntry: TimelineEntry {
    let date: Date
    let snapshot: ResidencyWidgetSnapshot
}

struct CountryTrackerWidgetEntryView: View {
    var entry: CountryTrackerWidgetProvider.Entry
    
    var body: some View {
        SmallWidgetView(snapshot: entry.snapshot)
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    let snapshot: ResidencyWidgetSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(flagEmoji(for: snapshot.homeCountryCode))
                Text("\(snapshot.homeCountryCode) • 365d")
            }
                .font(.caption2)
                .foregroundColor(.gray)

            if snapshot.daysRemaining == 0 {
                Text("Unsafe")
                    .font(.title3.weight(.bold))
                if let nextSafeEntryDate = snapshot.nextSafeEntryDate {
                    Text("Next entry \(formattedDate(nextSafeEntryDate))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                } else {
                    Text("No safe entry yet")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                Text("\(snapshot.daysRemaining)d left")
                    .font(.title3.weight(.bold))
                Text("Used \(snapshot.daysUsed)d")
                    .font(.caption2)
                    .foregroundColor(.gray)
                if let safeUntilDate = snapshot.safeUntilDate {
                    Text("Stay until \(formattedDate(safeUntilDate))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
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
        .configurationDisplayName("Residency Risk")
        .description("Safe days remaining for your home country")
    }
}

#Preview("Small", as: .systemSmall) {
    CountryTrackerWidget()
} timeline: {
    CountryTrackerEntry(
        date: Date(),
        snapshot: ResidencyWidgetSnapshot(
            homeCountryCode: "RU",
            daysUsed: 100,
            daysRemaining: 82,
            nextSafeEntryDate: Date(),
            safeUntilDate: Calendar.current.date(byAdding: .day, value: 82, to: Date()),
            lastUpdated: Date()
        )
    )
}
