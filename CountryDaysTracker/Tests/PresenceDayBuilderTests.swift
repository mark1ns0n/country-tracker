//
//  PresenceDayBuilderTests.swift
//
//  Created on 14 March 2026.
//

import XCTest
import SwiftData
@testable import CountryDaysTracker

@MainActor
final class PresenceDayBuilderTests: XCTestCase {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testBuilderCreatesOneRecordPerOverlappingCalendarDay() {
        let builder = PresenceDayBuilder(
            calendar: utcCalendar,
            nowProvider: { Self.date("2026-03-14T12:00:00Z") }
        )

        let records = builder.build(from: [
            StayInterval(
                countryCode: "AE",
                entryAt: Self.date("2026-03-10T23:30:00Z"),
                exitAt: Self.date("2026-03-12T00:10:00Z"),
                source: "test",
                confidence: 1
            )
        ])

        XCTAssertEqual(records.count, 3)
        XCTAssertEqual(records.map(\.countryCode), ["AE", "AE", "AE"])
        XCTAssertEqual(records.map(\.date), [
            Self.date("2026-03-10T00:00:00Z"),
            Self.date("2026-03-11T00:00:00Z"),
            Self.date("2026-03-12T00:00:00Z"),
        ])
    }

    func testBuilderKeepsBothCountriesOnSplitDay() {
        let builder = PresenceDayBuilder(calendar: utcCalendar)

        let records = builder.build(from: [
            StayInterval(
                countryCode: "RU",
                entryAt: Self.date("2026-03-10T00:30:00Z"),
                exitAt: Self.date("2026-03-10T08:00:00Z"),
                source: "test",
                confidence: 1
            ),
            StayInterval(
                countryCode: "AE",
                entryAt: Self.date("2026-03-10T09:00:00Z"),
                exitAt: Self.date("2026-03-10T20:00:00Z"),
                source: "test",
                confidence: 1
            ),
        ])

        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(Set(records.map(\.countryCode)), Set(["RU", "AE"]))
        XCTAssertEqual(Set(records.map(\.date)), Set([Self.date("2026-03-10T00:00:00Z")]))
    }

    func testBuilderUsesInjectedNowForOpenIntervals() {
        let builder = PresenceDayBuilder(
            calendar: utcCalendar,
            nowProvider: { Self.date("2026-03-12T12:00:00Z") }
        )

        let records = builder.build(from: [
            StayInterval(
                countryCode: "AE",
                entryAt: Self.date("2026-03-10T09:00:00Z"),
                exitAt: nil,
                source: "test",
                confidence: 1
            )
        ])

        XCTAssertEqual(records.map(\.date), [
            Self.date("2026-03-10T00:00:00Z"),
            Self.date("2026-03-11T00:00:00Z"),
            Self.date("2026-03-12T00:00:00Z"),
        ])
    }

    func testBackfillIsIdempotent() throws {
        let container = try AppModelSchema.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let service = PresenceDayBackfillService(
            modelContext: context,
            builder: PresenceDayBuilder(calendar: utcCalendar)
        )

        context.insert(
            StayInterval(
                countryCode: "RU",
                entryAt: Self.date("2026-03-10T10:00:00Z"),
                exitAt: Self.date("2026-03-11T10:00:00Z"),
                source: "test",
                confidence: 1
            )
        )
        try context.save()

        _ = try service.rebuildFromIntervals()
        _ = try service.rebuildFromIntervals()

        let descriptor = FetchDescriptor<PresenceDay>(
            sortBy: [
                SortDescriptor(\.date, order: .forward),
                SortDescriptor(\.countryCode, order: .forward),
            ]
        )
        let days = try context.fetch(descriptor)

        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days.map(\.countryCode), ["RU", "RU"])
    }

    func testBackfillPreservesManualOverrides() throws {
        let container = try AppModelSchema.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let service = PresenceDayBackfillService(
            modelContext: context,
            builder: PresenceDayBuilder(calendar: utcCalendar)
        )

        context.insert(
            PresenceDay(
                date: Self.date("2026-03-10T00:00:00Z"),
                countryCode: "RU",
                source: "manual",
                isManualOverride: true
            )
        )
        context.insert(
            StayInterval(
                countryCode: "RU",
                entryAt: Self.date("2026-03-10T06:00:00Z"),
                exitAt: Self.date("2026-03-10T09:00:00Z"),
                source: "test",
                confidence: 1
            )
        )
        try context.save()

        let insertedCount = try service.rebuildFromIntervals()

        let descriptor = FetchDescriptor<PresenceDay>(
            sortBy: [SortDescriptor(\.source, order: .forward)]
        )
        let days = try context.fetch(descriptor)

        XCTAssertEqual(insertedCount, 0)
        XCTAssertEqual(days.count, 1)
        XCTAssertEqual(days.first?.source, "manual")
        XCTAssertEqual(days.first?.countryCode, "RU")
    }

    func testBackfillSkipsEntireDayWhenManualOverrideExists() throws {
        let container = try AppModelSchema.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let service = PresenceDayBackfillService(
            modelContext: context,
            builder: PresenceDayBuilder(calendar: utcCalendar)
        )

        context.insert(
            PresenceDay(
                date: Self.date("2026-03-10T00:00:00Z"),
                countryCode: "AE",
                source: "manual",
                isManualOverride: true
            )
        )
        context.insert(
            StayInterval(
                countryCode: "RU",
                entryAt: Self.date("2026-03-10T01:00:00Z"),
                exitAt: Self.date("2026-03-10T23:00:00Z"),
                source: "test",
                confidence: 1
            )
        )
        try context.save()

        let insertedCount = try service.rebuildFromIntervals()
        let days = try context.fetch(FetchDescriptor<PresenceDay>())

        XCTAssertEqual(insertedCount, 0)
        XCTAssertEqual(days.count, 1)
        XCTAssertEqual(days.first?.countryCode, "AE")
        XCTAssertTrue(days.first?.isManualOverride == true)
    }

    func testClearOverrideRestoresDerivedRows() throws {
        let container = try AppModelSchema.makeContainer(inMemory: true)
        let context = ModelContext(container)
        context.insert(
            StayInterval(
                countryCode: "RU",
                entryAt: Self.date("2026-03-10T10:00:00Z"),
                exitAt: Self.date("2026-03-10T12:00:00Z"),
                source: "test",
                confidence: 1
            )
        )
        try context.save()

        let overrides = PresenceDayOverrideRepository(modelContext: context)
        try overrides.applyOverride(
            for: Self.date("2026-03-10T00:00:00Z"),
            countryCode: "AE",
            notes: "Manual correction"
        )
        try overrides.clearOverride(for: Self.date("2026-03-10T00:00:00Z"))

        let descriptor = FetchDescriptor<PresenceDay>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let days = try context.fetch(descriptor)

        XCTAssertEqual(days.count, 1)
        XCTAssertEqual(days.first?.countryCode, "RU")
        XCTAssertFalse(days.first?.isManualOverride == true)
    }

    func testBackfillEmptyStateReturnsNoRows() throws {
        let container = try AppModelSchema.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let service = PresenceDayBackfillService(
            modelContext: context,
            builder: PresenceDayBuilder(calendar: utcCalendar)
        )

        let insertedCount = try service.rebuildFromIntervals()
        let days = try context.fetch(FetchDescriptor<PresenceDay>())

        XCTAssertEqual(insertedCount, 0)
        XCTAssertTrue(days.isEmpty)
    }

    private static func date(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601)!
    }
}
