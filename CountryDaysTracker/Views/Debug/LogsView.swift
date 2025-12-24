//
//  LogsView.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI
import SwiftData

struct LogsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var logs: [LocationEventLog] = []
    
    var body: some View {
        List(logs, id: \.id) { log in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.countryCodeCandidate ?? "—")
                        .font(.headline)
                    Spacer()
                    Text(log.accepted ? "accepted" : "ignored")
                        .font(.caption)
                        .foregroundStyle(log.accepted ? .green : .red)
                }
                
                Text("lat: \(String(format: "%.4f", log.latitude)), lon: \(String(format: "%.4f", log.longitude))")
                    .font(.caption)
                
                Text("source: \(log.source)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if let note = log.note { Text(note).font(.caption2) }
            }
        }
        .navigationTitle("Logs (last 200)")
        .onAppear { refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .stayIntervalsDidChange)) { _ in
            refresh()
        }
    }
    
    private func refresh() {
        let repo = StayRepository(modelContext: modelContext)
        logs = repo.fetchRecentLogs(limit: 200)
    }
}

#Preview { LogsView() }
