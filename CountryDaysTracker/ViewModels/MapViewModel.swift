//
//  MapViewModel.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation
import MapKit
import SwiftData

@MainActor
final class MapViewModel: ObservableObject {
    @Published var rangeVM = RangeSelectionViewModel()
    @Published var visitedCountries: Set<String> = []
    @Published var overlays: [MKOverlay] = []
    
    private let repository: StayRepository
    private let aggregation = AggregationService()
    private let geometryStore = CountryGeometryStore()
    
    init(repository: StayRepository) {
        self.repository = repository
        refresh()
    }
    
    func refresh() {
        let intervals = repository.fetchIntervals(in: rangeVM.range)
        visitedCountries = aggregation.visitedCountries(range: rangeVM.range, intervals: intervals)
        var newOverlays: [MKOverlay] = []
        for code in visitedCountries {
            if let polys = geometryStore.polygonsByISO[code] {
                newOverlays.append(contentsOf: polys)
            }
        }
        overlays = newOverlays
    }
}
