//
//  StatsView.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var rangeVM = RangeSelectionViewModel()
    @State private var daysByCountry: [(code: String, days: Int)] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Year stats widget at the top
//                ScrollView {
//                    YearStatsWidget(repository: StayRepository(modelContext: modelContext))
//                }
//                .frame(height: 400)
//                .background(Color(.systemGray6))
//                
//                Divider()
                
                // Custom range selector
                VStack(spacing: 8) {
                    Picker("Range", selection: $rangeVM.preset) {
                        ForEach(RangePreset.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    List(daysByCountry, id: \.code) { item in
                        HStack(spacing: 12) {
                            Text(flagEmoji(for: item.code))
                            Text(item.code)
                                .font(.headline)
                            Spacer()
                            Text("\(item.days) d")
                                .bold()
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
        }
        .onChange(of: rangeVM.preset) { _ in refresh() }
        .onAppear { refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .stayIntervalsDidChange)) { _ in
            refresh()
        }
    }

    private func refresh() {
        let repo = StayRepository(modelContext: modelContext)
        let intervals = repo.fetchIntervals(in: rangeVM.range)
        let dict = AggregationService().daysByCountry(range: rangeVM.range, intervals: intervals)
        daysByCountry = dict.map { ($0.key, $0.value) }.sorted { $0.days > $1.days }
    }
}

#Preview { StatsView() }
