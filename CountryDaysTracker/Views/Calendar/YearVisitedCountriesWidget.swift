//
//  YearVisitedCountriesWidget.swift
//  CountryDaysTracker
//
//  Created on 14 January 2026.
//

import SwiftUI
import SwiftData

struct YearVisitedCountriesWidget: View {
    @Environment(\.modelContext) private var modelContext
    @State private var countryDays: [(code: String, days: Int, increaseInDays: Int?, decreaseInDays: Int?)] = []
    
    private let aggregation = AggregationService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last 365 Days")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(countryDays.count) countries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("↑ if arrive there today, ↓ if you do not go there")
                .font(.caption)
                .foregroundStyle(.secondary)

            if countryDays.isEmpty {
                Text("No countries visited yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(countryDays, id: \.code) { item in
                        HStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Text(flagEmoji(for: item.code))
                                    .font(.title3)
                                Text(item.code)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(item.days) d")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                Text(changeText(increaseInDays: item.increaseInDays, decreaseInDays: item.decreaseInDays))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        
                        if item.code != countryDays.last?.code {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .onAppear { refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .stayIntervalsDidChange)) { _ in
            refresh()
        }
    }
    
    private func refresh() {
        let repo = StayRepository(modelContext: modelContext)
        let range = DateUtils.last365DaysRange()
        let intervals = repo.fetchIntervals(in: range)
        let daysByCountry = aggregation.daysByCountry(range: range, intervals: intervals)
        let daysInRange = DateUtils.daysInRange(range)
        let dayCountries = aggregation.dayCountriesByDay(range: range, intervals: intervals)

        countryDays = daysByCountry
            .map { code, days in
                let changes = aggregation.daysUntilChangeForCountry(
                    targetCountry: code,
                    daysInRange: daysInRange,
                    dayCountries: dayCountries
                )
                return (
                    code: code,
                    days: days,
                    increaseInDays: changes.increaseInDays,
                    decreaseInDays: changes.decreaseInDays
                )
            }
            .sorted { lhs, rhs in
                lhs.days == rhs.days ? lhs.code < rhs.code : lhs.days > rhs.days
            }
    }

    private func changeText(increaseInDays: Int?, decreaseInDays: Int?) -> String {
        "↑ \(formatDays(increaseInDays))  ↓ \(formatDays(decreaseInDays))"
    }

    private func formatDays(_ days: Int?) -> String {
        guard let days else { return "—" }
        return "in \(days)d"
    }
}

#Preview {
    YearVisitedCountriesWidget()
}
