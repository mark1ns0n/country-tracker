//
//  DayDetailsSheet.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI
import SwiftData

struct DayDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let date: Date
    
    var body: some View {
        NavigationView {
            List(intervalsForDay(date)) { interval in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Country: \(interval.countryCode)")
                        .font(.headline)
                    
                    HStack {
                        Text("Entry: \(format(interval.entryAt))")
                        Spacer()
                        Text("Exit: \(format(interval.exitAt))")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func intervalsForDay(_ day: Date) -> [StayInterval] {
        let repo = StayRepository(modelContext: modelContext)
        let start = DateUtils.startOfDay(day)
        let end = DateUtils.endOfDay(day)
        return repo.fetchIntervals(in: start...end)
    }
    
    private func format(_ date: Date?) -> String {
        guard let date else { return "—" }
        let fmt = DateFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

extension StayInterval: Identifiable {}
