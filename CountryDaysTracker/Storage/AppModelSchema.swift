//
//  AppModelSchema.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation
import SwiftData

enum AppModelSchema {
    private static let appGroupIdentifier = "group.com.mark1ns0n.countrydaystracker"
    private static let persistentStoreFilename = "default.store"
    static let schema = Schema(versionedSchema: AppSchemaV2.self)

    static func makeContainer(
        inMemory: Bool,
        url: URL? = nil
    ) throws -> ModelContainer {
        if !inMemory, url == nil {
            try ensurePersistentStoreDirectoryExists()
        }

        do {
            return try makeVersionedContainer(
                inMemory: inMemory,
                url: url
            )
        } catch {
            guard
                !inMemory,
                let storeURL = url ?? defaultPersistentStoreURL(),
                isUnknownModelVersionError(error)
            else {
                throw error
            }

            try recoverUnknownVersionStore(at: storeURL)
            return try makeVersionedContainer(
                inMemory: false,
                url: storeURL
            )
        }
    }

    static func legacySchema() -> Schema {
        Schema(versionedSchema: AppSchemaV1.self)
    }

    static func currentUnversionedSchema() -> Schema {
        Schema([
            StayInterval.self,
            LocationEventLog.self,
            PresenceDay.self,
            ResidencyProfile.self,
            ResidencyRule.self,
        ])
    }

    static func legacyUnversionedSchema() -> Schema {
        Schema([
            StayInterval.self,
            LocationEventLog.self,
        ])
    }

    private static func makeVersionedContainer(
        inMemory: Bool,
        url: URL?
    ) throws -> ModelContainer {
        let configuration = configuration(
            inMemory: inMemory,
            url: url
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private static func configuration(
        inMemory: Bool,
        url: URL?
    ) -> ModelConfiguration {
        if let url = url ?? defaultPersistentStoreURL() {
            return ModelConfiguration(
                "CountryDaysTracker",
                schema: schema,
                url: url,
                allowsSave: true,
                cloudKitDatabase: .none
            )
        }

        return ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
    }

    private static func defaultPersistentStoreURL() -> URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return nil
        }

        return containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(persistentStoreFilename, isDirectory: false)
    }

    private static func ensurePersistentStoreDirectoryExists() throws {
        guard let storeURL = defaultPersistentStoreURL() else { return }
        let directoryURL = storeURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    private static func isUnknownModelVersionError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain, nsError.code == 134504 {
            return true
        }

        let message = nsError.localizedDescription.lowercased()
        return message.contains("unknown model version")
    }

    private static func recoverUnknownVersionStore(at storeURL: URL) throws {
        let snapshot = try makeLegacySnapshot(from: storeURL)
        try backupStoreFiles(at: storeURL)
        try removeStoreFiles(at: storeURL)

        let recoveredContainer = try makeVersionedContainer(
            inMemory: false,
            url: storeURL
        )
        let recoveredContext = ModelContext(recoveredContainer)

        snapshot.stayIntervals.forEach { recoveredContext.insert($0.makeModel()) }
        snapshot.locationLogs.forEach { recoveredContext.insert($0.makeModel()) }
        snapshot.presenceDays.forEach { recoveredContext.insert($0.makeModel()) }
        snapshot.residencyProfiles.forEach { recoveredContext.insert($0.makeModel()) }
        snapshot.residencyRules.forEach { recoveredContext.insert($0.makeModel()) }

        if recoveredContext.hasChanges {
            try recoveredContext.save()
        }
    }

    private static func makeLegacySnapshot(from storeURL: URL) throws -> LegacyStoreSnapshot {
        let legacyAttempts: [(Schema, Bool)] = [
            (currentUnversionedSchema(), true),
            (legacyUnversionedSchema(), false),
        ]

        var lastError: Error?

        for (schema, includesResidencyModels) in legacyAttempts {
            do {
                let configuration = ModelConfiguration(
                    "CountryDaysTrackerLegacyRecovery",
                    schema: schema,
                    url: storeURL,
                    allowsSave: false,
                    cloudKitDatabase: .none
                )
                let container = try ModelContainer(
                    for: schema,
                    configurations: [configuration]
                )
                let context = ModelContext(container)

                let stayIntervals = try context.fetch(FetchDescriptor<StayInterval>())
                    .map(LegacyStayIntervalSnapshot.init)
                let locationLogs = try context.fetch(FetchDescriptor<LocationEventLog>())
                    .map(LegacyLocationEventLogSnapshot.init)

                if includesResidencyModels {
                    let presenceDays = try context.fetch(FetchDescriptor<PresenceDay>())
                        .map(LegacyPresenceDaySnapshot.init)
                    let residencyProfiles = try context.fetch(FetchDescriptor<ResidencyProfile>())
                        .map(LegacyResidencyProfileSnapshot.init)
                    let residencyRules = try context.fetch(FetchDescriptor<ResidencyRule>())
                        .map(LegacyResidencyRuleSnapshot.init)

                    return LegacyStoreSnapshot(
                        stayIntervals: stayIntervals,
                        locationLogs: locationLogs,
                        presenceDays: presenceDays,
                        residencyProfiles: residencyProfiles,
                        residencyRules: residencyRules
                    )
                }

                return LegacyStoreSnapshot(
                    stayIntervals: stayIntervals,
                    locationLogs: locationLogs,
                    presenceDays: [],
                    residencyProfiles: [],
                    residencyRules: []
                )
            } catch {
                lastError = error
            }
        }

        throw lastError ?? CocoaError(.fileReadUnknown)
    }

    private static func backupStoreFiles(at storeURL: URL) throws {
        let backupRoot = storeURL
            .deletingLastPathComponent()
            .appendingPathComponent("LegacyStoreBackups", isDirectory: true)
        try FileManager.default.createDirectory(
            at: backupRoot,
            withIntermediateDirectories: true
        )

        let timestamp = ISO8601DateFormatter()
            .string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let backupDirectory = backupRoot.appendingPathComponent(timestamp, isDirectory: true)
        try FileManager.default.createDirectory(
            at: backupDirectory,
            withIntermediateDirectories: true
        )

        for sourceURL in storeFamilyURLs(for: storeURL) where FileManager.default.fileExists(atPath: sourceURL.path) {
            let destinationURL = backupDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        }
    }

    private static func removeStoreFiles(at storeURL: URL) throws {
        for candidateURL in storeFamilyURLs(for: storeURL) where FileManager.default.fileExists(atPath: candidateURL.path) {
            try FileManager.default.removeItem(at: candidateURL)
        }
    }

    private static func storeFamilyURLs(for storeURL: URL) -> [URL] {
        [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal"),
        ]
    }
}

private struct LegacyStoreSnapshot {
    let stayIntervals: [LegacyStayIntervalSnapshot]
    let locationLogs: [LegacyLocationEventLogSnapshot]
    let presenceDays: [LegacyPresenceDaySnapshot]
    let residencyProfiles: [LegacyResidencyProfileSnapshot]
    let residencyRules: [LegacyResidencyRuleSnapshot]
}

private struct LegacyStayIntervalSnapshot {
    let id: UUID
    let countryCode: String
    let entryAt: Date
    let exitAt: Date?
    let source: String
    let confidence: Double
    let createdAt: Date
    let updatedAt: Date

    init(model: StayInterval) {
        id = model.id
        countryCode = model.countryCode
        entryAt = model.entryAt
        exitAt = model.exitAt
        source = model.source
        confidence = model.confidence
        createdAt = model.createdAt
        updatedAt = model.updatedAt
    }

    func makeModel() -> StayInterval {
        StayInterval(
            id: id,
            countryCode: countryCode,
            entryAt: entryAt,
            exitAt: exitAt,
            source: source,
            confidence: confidence,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct LegacyLocationEventLogSnapshot {
    let id: UUID
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let source: String
    let countryCodeCandidate: String?
    let accepted: Bool
    let note: String?

    init(model: LocationEventLog) {
        id = model.id
        timestamp = model.timestamp
        latitude = model.latitude
        longitude = model.longitude
        source = model.source
        countryCodeCandidate = model.countryCodeCandidate
        accepted = model.accepted
        note = model.note
    }

    func makeModel() -> LocationEventLog {
        LocationEventLog(
            id: id,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            source: source,
            countryCodeCandidate: countryCodeCandidate,
            accepted: accepted,
            note: note
        )
    }
}

private struct LegacyPresenceDaySnapshot {
    let id: UUID
    let date: Date
    let countryCode: String
    let source: String
    let isManualOverride: Bool
    let notes: String?
    let updatedAt: Date

    init(model: PresenceDay) {
        id = model.id
        date = model.date
        countryCode = model.countryCode
        source = model.source
        isManualOverride = model.isManualOverride
        notes = model.notes
        updatedAt = model.updatedAt
    }

    func makeModel() -> PresenceDay {
        PresenceDay(
            id: id,
            date: date,
            countryCode: countryCode,
            source: source,
            isManualOverride: isManualOverride,
            notes: notes,
            updatedAt: updatedAt
        )
    }
}

private struct LegacyResidencyProfileSnapshot {
    let id: UUID
    let homeCountryCode: String
    let activeRuleIdentifier: String?
    let updatedAt: Date

    init(model: ResidencyProfile) {
        id = model.id
        homeCountryCode = model.homeCountryCode
        activeRuleIdentifier = model.activeRuleIdentifier
        updatedAt = model.updatedAt
    }

    func makeModel() -> ResidencyProfile {
        ResidencyProfile(
            id: id,
            homeCountryCode: homeCountryCode,
            activeRuleIdentifier: activeRuleIdentifier,
            updatedAt: updatedAt
        )
    }
}

private struct LegacyResidencyRuleSnapshot {
    let id: UUID
    let identifier: String
    let jurisdictionCode: String
    let windowKind: String
    let windowLengthDays: Int
    let thresholdDays: Int
    let safeLimitDays: Int
    let isEnabled: Bool
    let title: String

    init(model: ResidencyRule) {
        id = model.id
        identifier = model.identifier
        jurisdictionCode = model.jurisdictionCode
        windowKind = model.windowKind
        windowLengthDays = model.windowLengthDays
        thresholdDays = model.thresholdDays
        safeLimitDays = model.safeLimitDays
        isEnabled = model.isEnabled
        title = model.title
    }

    func makeModel() -> ResidencyRule {
        ResidencyRule(
            id: id,
            identifier: identifier,
            jurisdictionCode: jurisdictionCode,
            windowKind: windowKind,
            windowLengthDays: windowLengthDays,
            thresholdDays: thresholdDays,
            safeLimitDays: safeLimitDays,
            isEnabled: isEnabled,
            title: title
        )
    }
}
