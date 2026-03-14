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
