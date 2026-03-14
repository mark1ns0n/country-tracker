//
//  StayRepository.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation
import SwiftData

extension Notification.Name {
    /// Broadcast when stay intervals are inserted or closed
    static let stayIntervalsDidChange = Notification.Name("stayIntervalsDidChange")
    static let locationLogsDidChange = Notification.Name("locationLogsDidChange")
    static let residencySettingsDidChange = Notification.Name("residencySettingsDidChange")
    static let presenceDaysDidChange = Notification.Name("presenceDaysDidChange")
}

private actor PresenceDayRefreshCoordinator {
    private var refreshTask: Task<Void, Never>?

    func scheduleRefresh(_ operation: @escaping @Sendable () -> Void) {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms debounce
            guard !Task.isCancelled else { return }
            operation()
        }
    }
}

@MainActor
class StayRepository {
    private let modelContext: ModelContext
    private let presenceDayRefreshCoordinator = PresenceDayRefreshCoordinator()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - StayInterval Methods
    
    /// Validate ISO A2 country code format
    private func isValidCountryCode(_ code: String) -> Bool {
        // ISO A2 codes are exactly 2 uppercase letters
        let pattern = "^[A-Z]{2}$"
        return code.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// Fetch the currently open interval (where exitAt is nil)
    func fetchOpenInterval() -> StayInterval? {
        let descriptor = FetchDescriptor<StayInterval>(
            predicate: #Predicate { $0.exitAt == nil },
            sortBy: [SortDescriptor(\.entryAt, order: .reverse)]
        )
        
        do {
            let intervals = try modelContext.fetch(descriptor)
            return intervals.first
        } catch {
            print("Error fetching open interval: \(error)")
            return nil
        }
    }
    
    /// Fetch all intervals within a date range
    func fetchIntervals(in range: ClosedRange<Date>) -> [StayInterval] {
        let startDate = range.lowerBound
        let endDate = range.upperBound
        
        let descriptor = FetchDescriptor<StayInterval>(
            predicate: #Predicate { interval in
                (interval.entryAt <= endDate) && ((interval.exitAt ?? endDate) >= startDate)
            },
            sortBy: [SortDescriptor(\.entryAt, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching intervals in range: \(error)")
            return []
        }
    }
    
    /// Insert a new interval
    func insertInterval(
        countryCode: String,
        entryAt: Date,
        exitAt: Date? = nil,
        source: String,
        confidence: Double
    ) {
        // Validate country code before inserting
        let normalizedCode = countryCode.uppercased()
        guard isValidCountryCode(normalizedCode) else {
            print("⚠️ Invalid country code rejected: '\(countryCode)'")
            return
        }
        
        let interval = StayInterval(
            countryCode: normalizedCode,
            entryAt: entryAt,
            exitAt: exitAt,
            source: source,
            confidence: confidence
        )
        
        modelContext.insert(interval)
        
        do {
            try modelContext.save()
            scheduleDerivedDataRefresh()
            NotificationCenter.default.post(name: .stayIntervalsDidChange, object: nil)
        } catch {
            print("Error inserting interval: \(error)")
        }
    }
    
    /// Close an interval by setting its exitAt date
    func closeInterval(id: UUID, exitAt: Date) {
        let descriptor = FetchDescriptor<StayInterval>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let intervals = try modelContext.fetch(descriptor)
            if let interval = intervals.first {
                interval.exitAt = exitAt
                interval.updatedAt = Date()
                try modelContext.save()
                scheduleDerivedDataRefresh()
                NotificationCenter.default.post(name: .stayIntervalsDidChange, object: nil)
            }
        } catch {
            print("Error closing interval: \(error)")
        }
    }
    
    // MARK: - LocationEventLog Methods
    
    /// Append a new location event log
    func appendLog(
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double,
        source: String,
        countryCodeCandidate: String? = nil,
        accepted: Bool = false,
        note: String? = nil
    ) {
        let log = LocationEventLog(
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            source: source,
            countryCodeCandidate: countryCodeCandidate,
            accepted: accepted,
            note: note
        )
        
        modelContext.insert(log)
        
        do {
            try modelContext.save()
            NotificationCenter.default.post(name: .locationLogsDidChange, object: nil)
        } catch {
            print("Error appending log: \(error)")
        }
    }
    
    /// Fetch recent logs (for debugging)
    func fetchRecentLogs(limit: Int = 200) -> [LocationEventLog] {
        let descriptor = FetchDescriptor<LocationEventLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let logs = try modelContext.fetch(descriptor)
            return Array(logs.prefix(limit))
        } catch {
            print("Error fetching logs: \(error)")
            return []
        }
    }
    
    private func scheduleDerivedDataRefresh() {
        Task {
            await presenceDayRefreshCoordinator.scheduleRefresh { [weak self] in
                Task { @MainActor in
                    self?.rebuildPresenceDays()
                }
            }
        }
    }

    private func rebuildPresenceDays() {
        do {
            _ = try PresenceDayBackfillService(modelContext: modelContext).rebuildFromIntervals()
            ResidencyWidgetSyncService(modelContext: modelContext).sync()
            NotificationCenter.default.post(name: .presenceDaysDidChange, object: nil)
        } catch {
            print("Failed to rebuild presence days: \(error)")
        }
    }
}
