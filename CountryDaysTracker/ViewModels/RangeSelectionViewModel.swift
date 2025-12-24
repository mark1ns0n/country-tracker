//
//  RangeSelectionViewModel.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation

enum RangePreset: String, CaseIterable, Identifiable {
    case last30 = "Last 30"
    case last90 = "Last 90"
    case thisYear = "This Year"
    case custom = "Custom"
    
    var id: String { rawValue }
}

final class RangeSelectionViewModel: ObservableObject {
    @Published var preset: RangePreset = .last30 {
        didSet { updateRange() }
    }
    @Published var range: ClosedRange<Date>
    private let calendar = Calendar.current
    
    init() {
        let now = Date()
        range = now.addingTimeInterval(-30*24*3600)...now
        updateRange()
    }
    
    func updateRange() {
        let now = Date()
        switch preset {
        case .last30:
            range = now.addingTimeInterval(-30*24*3600)...now
        case .last90:
            range = now.addingTimeInterval(-90*24*3600)...now
        case .thisYear:
            let startOfYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: 1, day: 1)) ?? now
            range = startOfYear...now
        case .custom:
            // Keep current custom range
            break
        }
    }
}
