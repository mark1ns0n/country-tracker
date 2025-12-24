//
//  StatsViewModel.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation
import SwiftData

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var rangeVM = RangeSelectionViewModel()
    @Published var daysByCountry: [(code: String, days: Int)] = []
    
    private let repository: StayRepository
    private let aggregation = AggregationService()
    
    init(repository: StayRepository) {
        self.repository = repository
        refresh()
    }
    
    func refresh() {
        let intervals = repository.fetchIntervals(in: rangeVM.range)
        let dict = aggregation.daysByCountry(range: rangeVM.range, intervals: intervals)
        daysByCountry = dict.map { ($0.key, $0.value) }.sorted { $0.days > $1.days }
    }
}
