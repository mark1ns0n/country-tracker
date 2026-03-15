//
//  AppMigrationPlanTests.swift
//
//  Created on 15 March 2026.
//

import XCTest
import SwiftData
@testable import CountryDaysTracker

@MainActor
final class AppMigrationPlanTests: XCTestCase {
    func testLegacyStoreMigratesAndPreservesData() throws {
        let storeURL = makeStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent()) }

        let legacySchema = AppModelSchema.legacySchema()
        let legacyConfiguration = ModelConfiguration(
            "CountryDaysTrackerLegacy",
            schema: legacySchema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let legacyContainer = try ModelContainer(
            for: legacySchema,
            configurations: [legacyConfiguration]
        )
        let legacyContext = ModelContext(legacyContainer)
        legacyContext.insert(
            StayInterval(
                countryCode: "RU",
                entryAt: Self.day("2026-02-01"),
                exitAt: Self.day("2026-02-03"),
                source: "test",
                confidence: 1
            )
        )
        legacyContext.insert(
            LocationEventLog(
                timestamp: Self.day("2026-02-01"),
                latitude: 55.75,
                longitude: 37.61,
                source: "test",
                countryCodeCandidate: "RU",
                accepted: true
            )
        )
        try legacyContext.save()

        let migratedContainer = try AppModelSchema.makeContainer(
            inMemory: false,
            url: storeURL
        )
        let migratedContext = ModelContext(migratedContainer)

        let intervals = try migratedContext.fetch(FetchDescriptor<StayInterval>())
        let logs = try migratedContext.fetch(FetchDescriptor<LocationEventLog>())
        XCTAssertEqual(intervals.count, 1)
        XCTAssertEqual(logs.count, 1)

        let settingsRepository = ResidencySettingsRepository(modelContext: migratedContext)
        let profile = try settingsRepository.ensureDefaults()
        XCTAssertEqual(profile.homeCountryCode, "RU")

        let firstBackfillCount = try PresenceDayBackfillService(modelContext: migratedContext).rebuildFromIntervals()
        let secondBackfillCount = try PresenceDayBackfillService(modelContext: migratedContext).rebuildFromIntervals()
        let presenceDays = try migratedContext.fetch(FetchDescriptor<PresenceDay>())

        XCTAssertEqual(firstBackfillCount, 3)
        XCTAssertEqual(secondBackfillCount, 3)
        XCTAssertEqual(presenceDays.count, 3)
    }

    func testUnknownVersionCurrentStoreRecoversAndPreservesData() throws {
        let storeURL = makeStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent()) }

        let legacySchema = AppModelSchema.currentUnversionedSchema()
        let legacyConfiguration = ModelConfiguration(
            "CountryDaysTrackerLegacyCurrent",
            schema: legacySchema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let legacyContainer = try ModelContainer(
            for: legacySchema,
            configurations: [legacyConfiguration]
        )
        let legacyContext = ModelContext(legacyContainer)

        legacyContext.insert(
            StayInterval(
                id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                countryCode: "RU",
                entryAt: Self.day("2026-01-01"),
                exitAt: Self.day("2026-01-03"),
                source: "legacy.current",
                confidence: 1,
                createdAt: Self.day("2026-01-03"),
                updatedAt: Self.day("2026-01-03")
            )
        )
        legacyContext.insert(
            PresenceDay(
                id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
                date: Self.day("2026-01-02"),
                countryCode: "RU",
                source: "manual",
                isManualOverride: true,
                notes: "keep me",
                updatedAt: Self.day("2026-01-03")
            )
        )
        legacyContext.insert(
            ResidencyProfile(
                id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
                homeCountryCode: "RU",
                activeRuleIdentifier: "ru-183-rolling-365",
                updatedAt: Self.day("2026-01-03")
            )
        )
        legacyContext.insert(
            ResidencyRule(
                id: UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!,
                identifier: "ru-183-rolling-365",
                jurisdictionCode: "RU",
                windowLengthDays: 365,
                thresholdDays: 183,
                safeLimitDays: 182,
                isEnabled: true,
                title: "Russia: 183 days in 365-day window"
            )
        )
        try legacyContext.save()

        let migratedContainer = try AppModelSchema.makeContainer(
            inMemory: false,
            url: storeURL
        )
        let migratedContext = ModelContext(migratedContainer)

        let intervals = try migratedContext.fetch(FetchDescriptor<StayInterval>())
        let presenceDays = try migratedContext.fetch(FetchDescriptor<PresenceDay>())
        let profiles = try migratedContext.fetch(FetchDescriptor<ResidencyProfile>())
        let rules = try migratedContext.fetch(FetchDescriptor<ResidencyRule>())

        XCTAssertEqual(intervals.count, 1)
        XCTAssertEqual(intervals.first?.countryCode, "RU")
        XCTAssertEqual(presenceDays.count, 1)
        XCTAssertEqual(presenceDays.first?.notes, "keep me")
        XCTAssertEqual(profiles.first?.homeCountryCode, "RU")
        XCTAssertEqual(rules.first?.identifier, "ru-183-rolling-365")

        let backupDirectories = try FileManager.default.contentsOfDirectory(
            at: storeURL.deletingLastPathComponent().appendingPathComponent("LegacyStoreBackups"),
            includingPropertiesForKeys: nil
        )
        XCTAssertFalse(backupDirectories.isEmpty)
    }

    func testCopiedRealDeviceStoreRecovers() throws {
        let sourceDirectory = URL(fileURLWithPath: "/tmp/country-tracker-device-store/appGroup", isDirectory: true)
        try XCTSkipUnless(
            FileManager.default.fileExists(atPath: sourceDirectory.appendingPathComponent("default.store").path),
            "Real device store snapshot is not available locally."
        )

        let workingDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        let destinationStoreURL = workingDirectory.appendingPathComponent("default.store")
        for filename in ["default.store", "default.store-wal", "default.store-shm"] {
            let sourceURL = sourceDirectory.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: sourceURL.path) {
                try FileManager.default.copyItem(
                    at: sourceURL,
                    to: workingDirectory.appendingPathComponent(filename)
                )
            }
        }

        let migratedContainer = try AppModelSchema.makeContainer(
            inMemory: false,
            url: destinationStoreURL
        )
        let migratedContext = ModelContext(migratedContainer)

        let intervals = try migratedContext.fetch(FetchDescriptor<StayInterval>())
        let logs = try migratedContext.fetch(FetchDescriptor<LocationEventLog>())
        let presenceDays = try migratedContext.fetch(FetchDescriptor<PresenceDay>())

        XCTAssertEqual(intervals.count, 17)
        XCTAssertEqual(logs.count, 2696)
        XCTAssertEqual(presenceDays.count, 1468)
    }

    private func makeStoreURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("CountryDaysTracker.store")
    }

    private static func day(_ isoDay: String) -> Date {
        ISO8601DateFormatter().date(from: "\(isoDay)T00:00:00Z")!
    }
}
