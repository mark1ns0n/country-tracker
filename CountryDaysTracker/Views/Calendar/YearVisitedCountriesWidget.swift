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
    @State private var countryDays: [(code: String, days: Int)] = []
    
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
                            Text("\(item.days) d")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
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
        let oneYearAgo = Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        let range = oneYearAgo...Date()
        let intervals = repo.fetchIntervals(in: range)
        let daysByCountry = aggregation.daysByCountry(range: range, intervals: intervals)
        countryDays = daysByCountry.map { ($0.key, $0.value) }.sorted { $0.days > $1.days }
    }
    
    private func flagEmoji(for isoCountryCode: String) -> String {
        let upper = isoCountryCode.uppercased()
        guard upper.count == 2 else { return "🏳️" }
        let base: UInt32 = 127397 // Regional Indicator Symbol Letter A
        var s = ""
        for scalar in upper.unicodeScalars {
            if let u = UnicodeScalar(base + scalar.value) {
                s.append(String(u))
            }
        }
        return s
    }
}

#Preview {
    YearVisitedCountriesWidget()
}
