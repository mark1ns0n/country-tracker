//
//  AppModelSchema.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation
import SQLite3
import SwiftData

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

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
                FileManager.default.fileExists(atPath: storeURL.path)
            else {
                throw error
            }

            print("⚠️ Persistent container open failed, attempting SQLite recovery: \(error)")

            let snapshot = try makeSQLiteSnapshot(from: storeURL)

            do {
                try recoverUnknownVersionStore(
                    at: storeURL,
                    snapshot: snapshot
                )
                return try makeVersionedContainer(
                    inMemory: false,
                    url: storeURL
                )
            } catch {
                print("⚠️ Persistent store recovery failed: \(error)")
                return try makeSeededInMemoryContainer(from: snapshot)
            }
        }
    }

    static func legacySchema() -> Schema {
        Schema(versionedSchema: AppSchemaV1.self)
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
        if inMemory {
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
        }

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
            isStoredInMemoryOnly: true
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

    private static func recoverUnknownVersionStore(
        at storeURL: URL,
        snapshot: LegacyStoreSnapshot
    ) throws {
        try backupStoreFiles(at: storeURL)
        try removeStoreFiles(at: storeURL)

        let recoveredContainer = try makeVersionedContainer(
            inMemory: false,
            url: storeURL
        )
        let recoveredContext = ModelContext(recoveredContainer)
        seed(snapshot: snapshot, into: recoveredContext)

        if recoveredContext.hasChanges {
            try recoveredContext.save()
        }
    }

    private static func makeSeededInMemoryContainer(
        from snapshot: LegacyStoreSnapshot
    ) throws -> ModelContainer {
        let container = try makeVersionedContainer(
            inMemory: true,
            url: nil
        )
        let context = ModelContext(container)
        seed(snapshot: snapshot, into: context)
        if context.hasChanges {
            try context.save()
        }
        return container
    }

    private static func makeSQLiteSnapshot(from storeURL: URL) throws -> LegacyStoreSnapshot {
        var database: OpaquePointer?
        guard sqlite3_open_v2(storeURL.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            throw SQLiteRecoveryError.openFailed(message: currentSQLiteErrorMessage(database))
        }
        defer { sqlite3_close(database) }

        return LegacyStoreSnapshot(
            stayIntervals: try readStayIntervals(from: database),
            locationLogs: try readLocationEventLogs(from: database),
            presenceDays: try readPresenceDays(from: database),
            residencyProfiles: try readResidencyProfiles(from: database),
            residencyRules: try readResidencyRules(from: database)
        )
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

    private static func readStayIntervals(
        from database: OpaquePointer?
    ) throws -> [LegacyStayIntervalSnapshot] {
        guard try tableExists(named: "ZSTAYINTERVAL", in: database) else { return [] }
        let statement = try prepareStatement(
            """
            SELECT ZID, ZCOUNTRYCODE, ZENTRYAT, ZEXITAT, ZSOURCE, ZCONFIDENCE, ZCREATEDAT, ZUPDATEDAT
            FROM ZSTAYINTERVAL
            """,
            in: database
        )
        defer { sqlite3_finalize(statement) }

        var values: [LegacyStayIntervalSnapshot] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            values.append(
                LegacyStayIntervalSnapshot(
                    id: try uuidValue(statement, index: 0),
                    countryCode: stringValue(statement, index: 1) ?? "",
                    entryAt: try dateValue(statement, index: 2),
                    exitAt: try optionalDateValue(statement, index: 3),
                    source: stringValue(statement, index: 4) ?? "",
                    confidence: sqlite3_column_double(statement, 5),
                    createdAt: try dateValue(statement, index: 6),
                    updatedAt: try dateValue(statement, index: 7)
                )
            )
        }
        return values
    }

    private static func readLocationEventLogs(
        from database: OpaquePointer?
    ) throws -> [LegacyLocationEventLogSnapshot] {
        guard try tableExists(named: "ZLOCATIONEVENTLOG", in: database) else { return [] }
        let statement = try prepareStatement(
            """
            SELECT ZID, ZTIMESTAMP, ZLATITUDE, ZLONGITUDE, ZSOURCE, ZCOUNTRYCODECANDIDATE, ZACCEPTED, ZNOTE
            FROM ZLOCATIONEVENTLOG
            """,
            in: database
        )
        defer { sqlite3_finalize(statement) }

        var values: [LegacyLocationEventLogSnapshot] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            values.append(
                LegacyLocationEventLogSnapshot(
                    id: try uuidValue(statement, index: 0),
                    timestamp: try dateValue(statement, index: 1),
                    latitude: sqlite3_column_double(statement, 2),
                    longitude: sqlite3_column_double(statement, 3),
                    source: stringValue(statement, index: 4) ?? "",
                    countryCodeCandidate: stringValue(statement, index: 5),
                    accepted: sqlite3_column_int(statement, 6) != 0,
                    note: stringValue(statement, index: 7)
                )
            )
        }
        return values
    }

    private static func readPresenceDays(
        from database: OpaquePointer?
    ) throws -> [LegacyPresenceDaySnapshot] {
        guard try tableExists(named: "ZPRESENCEDAY", in: database) else { return [] }
        let statement = try prepareStatement(
            """
            SELECT ZID, ZDATE, ZCOUNTRYCODE, ZSOURCE, ZISMANUALOVERRIDE, ZUPDATEDAT
            FROM ZPRESENCEDAY
            """,
            in: database
        )
        defer { sqlite3_finalize(statement) }

        var values: [LegacyPresenceDaySnapshot] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            values.append(
                LegacyPresenceDaySnapshot(
                    id: try uuidValue(statement, index: 0),
                    date: try dateValue(statement, index: 1),
                    countryCode: stringValue(statement, index: 2) ?? "",
                    source: stringValue(statement, index: 3) ?? "",
                    isManualOverride: sqlite3_column_int(statement, 4) != 0,
                    notes: nil,
                    updatedAt: try dateValue(statement, index: 5)
                )
            )
        }
        return values
    }

    private static func readResidencyProfiles(
        from database: OpaquePointer?
    ) throws -> [LegacyResidencyProfileSnapshot] {
        guard try tableExists(named: "ZRESIDENCYPROFILE", in: database) else { return [] }
        let statement = try prepareStatement(
            """
            SELECT ZID, ZHOMECOUNTRYCODE, ZACTIVERULEIDENTIFIER, ZUPDATEDAT
            FROM ZRESIDENCYPROFILE
            """,
            in: database
        )
        defer { sqlite3_finalize(statement) }

        var values: [LegacyResidencyProfileSnapshot] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            values.append(
                LegacyResidencyProfileSnapshot(
                    id: try uuidValue(statement, index: 0),
                    homeCountryCode: stringValue(statement, index: 1) ?? "",
                    activeRuleIdentifier: stringValue(statement, index: 2),
                    updatedAt: try dateValue(statement, index: 3)
                )
            )
        }
        return values
    }

    private static func readResidencyRules(
        from database: OpaquePointer?
    ) throws -> [LegacyResidencyRuleSnapshot] {
        guard try tableExists(named: "ZRESIDENCYRULE", in: database) else { return [] }
        let statement = try prepareStatement(
            """
            SELECT ZID, ZIDENTIFIER, ZJURISDICTIONCODE, ZWINDOWKIND, ZWINDOWLENGTHDAYS, ZTHRESHOLDDAYS, ZSAFELIMITDAYS, ZISENABLED, ZTITLE
            FROM ZRESIDENCYRULE
            """,
            in: database
        )
        defer { sqlite3_finalize(statement) }

        var values: [LegacyResidencyRuleSnapshot] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            values.append(
                LegacyResidencyRuleSnapshot(
                    id: try uuidValue(statement, index: 0),
                    identifier: stringValue(statement, index: 1) ?? "",
                    jurisdictionCode: stringValue(statement, index: 2) ?? "",
                    windowKind: stringValue(statement, index: 3) ?? "",
                    windowLengthDays: Int(sqlite3_column_int(statement, 4)),
                    thresholdDays: Int(sqlite3_column_int(statement, 5)),
                    safeLimitDays: Int(sqlite3_column_int(statement, 6)),
                    isEnabled: sqlite3_column_int(statement, 7) != 0,
                    title: stringValue(statement, index: 8) ?? ""
                )
            )
        }
        return values
    }

    private static func tableExists(
        named tableName: String,
        in database: OpaquePointer?
    ) throws -> Bool {
        let statement = try prepareStatement(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
            in: database
        )
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, tableName, -1, SQLITE_TRANSIENT)
        return sqlite3_step(statement) == SQLITE_ROW
    }

    private static func prepareStatement(
        _ sql: String,
        in database: OpaquePointer?
    ) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteRecoveryError.statementPreparationFailed(
                sql: sql,
                message: currentSQLiteErrorMessage(database)
            )
        }
        return statement
    }

    private static func currentSQLiteErrorMessage(_ database: OpaquePointer?) -> String {
        guard let message = sqlite3_errmsg(database) else { return "Unknown SQLite error" }
        return String(cString: message)
    }

    private static func stringValue(
        _ statement: OpaquePointer?,
        index: Int32
    ) -> String? {
        guard let rawValue = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: rawValue)
    }

    private static func dateValue(
        _ statement: OpaquePointer?,
        index: Int32
    ) throws -> Date {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else {
            throw SQLiteRecoveryError.invalidDate(columnIndex: Int(index))
        }
        return Date(timeIntervalSinceReferenceDate: sqlite3_column_double(statement, index))
    }

    private static func optionalDateValue(
        _ statement: OpaquePointer?,
        index: Int32
    ) throws -> Date? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return try dateValue(statement, index: index)
    }

    private static func uuidValue(
        _ statement: OpaquePointer?,
        index: Int32
    ) throws -> UUID {
        guard
            let bytes = sqlite3_column_blob(statement, index),
            sqlite3_column_bytes(statement, index) == 16
        else {
            throw SQLiteRecoveryError.invalidUUID(columnIndex: Int(index))
        }

        var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &uuid) { destination in
            destination.copyBytes(from: UnsafeRawBufferPointer(start: bytes, count: 16))
        }
        return UUID(uuid: uuid)
    }

    private static func seed(
        snapshot: LegacyStoreSnapshot,
        into context: ModelContext
    ) {
        snapshot.stayIntervals.forEach { context.insert($0.makeModel()) }
        snapshot.locationLogs.forEach { context.insert($0.makeModel()) }
        snapshot.presenceDays.forEach { context.insert($0.makeModel()) }
        snapshot.residencyProfiles.forEach { context.insert($0.makeModel()) }
        snapshot.residencyRules.forEach { context.insert($0.makeModel()) }
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

    init(
        id: UUID,
        countryCode: String,
        entryAt: Date,
        exitAt: Date?,
        source: String,
        confidence: Double,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.countryCode = countryCode
        self.entryAt = entryAt
        self.exitAt = exitAt
        self.source = source
        self.confidence = confidence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

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

    init(
        id: UUID,
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        source: String,
        countryCodeCandidate: String?,
        accepted: Bool,
        note: String?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.source = source
        self.countryCodeCandidate = countryCodeCandidate
        self.accepted = accepted
        self.note = note
    }

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

    init(
        id: UUID,
        date: Date,
        countryCode: String,
        source: String,
        isManualOverride: Bool,
        notes: String?,
        updatedAt: Date
    ) {
        self.id = id
        self.date = date
        self.countryCode = countryCode
        self.source = source
        self.isManualOverride = isManualOverride
        self.notes = notes
        self.updatedAt = updatedAt
    }

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

    init(
        id: UUID,
        homeCountryCode: String,
        activeRuleIdentifier: String?,
        updatedAt: Date
    ) {
        self.id = id
        self.homeCountryCode = homeCountryCode
        self.activeRuleIdentifier = activeRuleIdentifier
        self.updatedAt = updatedAt
    }

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

    init(
        id: UUID,
        identifier: String,
        jurisdictionCode: String,
        windowKind: String,
        windowLengthDays: Int,
        thresholdDays: Int,
        safeLimitDays: Int,
        isEnabled: Bool,
        title: String
    ) {
        self.id = id
        self.identifier = identifier
        self.jurisdictionCode = jurisdictionCode
        self.windowKind = windowKind
        self.windowLengthDays = windowLengthDays
        self.thresholdDays = thresholdDays
        self.safeLimitDays = safeLimitDays
        self.isEnabled = isEnabled
        self.title = title
    }

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

private enum SQLiteRecoveryError: Error {
    case openFailed(message: String)
    case statementPreparationFailed(sql: String, message: String)
    case invalidUUID(columnIndex: Int)
    case invalidDate(columnIndex: Int)
}
