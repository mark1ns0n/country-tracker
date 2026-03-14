//
//  ResidencyEngineTests.swift
//
//  Created on 14 March 2026.
//

import XCTest
@testable import CountryDaysTracker

final class ResidencyEngineTests: XCTestCase {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var defaultRule: ResidencyRuleConfiguration {
        ResidencyRuleConfiguration(
            identifier: "ru-183-rolling-365",
            title: "Russia: 183 days in 365-day window",
            jurisdictionCode: "RU",
            windowKind: "rollingDays",
            windowLengthDays: 365,
            thresholdDays: 183,
            safeLimitDays: 182
        )
    }

    func testEmptyHistoryHasFullSafeAllowance() {
        let engine = ResidencyEngine(calendar: utcCalendar)
        let asOf = Self.day("2026-03-14")

        let evaluation = engine.evaluate(
            asOf: asOf,
            homeCountryCode: "RU",
            rule: defaultRule,
            presenceDays: []
        )

        XCTAssertEqual(evaluation.daysUsed, 0)
        XCTAssertEqual(evaluation.daysRemaining, 182)
        XCTAssertEqual(evaluation.nextSafeEntryDate, asOf)
        XCTAssertEqual(evaluation.maxSafeStayIfEnterToday, 182)
        XCTAssertEqual(evaluation.breachDateIfStayFromToday, Self.day("2026-09-12"))
        XCTAssertEqual(evaluation.latestSafeExitDateIfEnterToday, Self.day("2026-09-11"))
        XCTAssertFalse(evaluation.isThresholdExceeded)
    }

    func testExistingHomeDaysReduceRemainingAllowance() {
        let engine = ResidencyEngine(calendar: utcCalendar)
        let asOf = Self.day("2026-03-14")
        let presenceDays = (0..<100).map { offset in
            ResidencyPresenceDay(
                date: utcCalendar.date(byAdding: .day, value: -(offset + 1), to: asOf)!,
                countryCode: "RU"
            )
        }

        let evaluation = engine.evaluate(
            asOf: asOf,
            homeCountryCode: "RU",
            rule: defaultRule,
            presenceDays: presenceDays
        )

        XCTAssertEqual(evaluation.daysUsed, 100)
        XCTAssertEqual(evaluation.daysRemaining, 82)
        XCTAssertEqual(evaluation.maxSafeStayIfEnterToday, 82)
        XCTAssertEqual(evaluation.breachDateIfStayFromToday, Self.day("2026-06-04"))
        XCTAssertEqual(evaluation.latestSafeExitDateIfEnterToday, Self.day("2026-06-03"))
    }

    func testNextSafeEntryMovesForwardWhenThresholdAlreadyExceeded() {
        let engine = ResidencyEngine(calendar: utcCalendar)
        let asOf = Self.day("2026-03-14")
        let presenceDays = (0..<183).map { offset in
            ResidencyPresenceDay(
                date: utcCalendar.date(byAdding: .day, value: -(364 - offset), to: asOf)!,
                countryCode: "RU"
            )
        }

        let evaluation = engine.evaluate(
            asOf: asOf,
            homeCountryCode: "RU",
            rule: defaultRule,
            presenceDays: presenceDays
        )

        XCTAssertEqual(evaluation.daysUsed, 183)
        XCTAssertTrue(evaluation.isThresholdExceeded)
        XCTAssertEqual(evaluation.daysRemaining, 0)
        XCTAssertEqual(evaluation.nextSafeEntryDate, Self.day("2026-03-16"))
        XCTAssertEqual(evaluation.maxSafeStayIfEnterToday, 0)
        XCTAssertEqual(evaluation.breachDateIfStayFromToday, asOf)
        XCTAssertNil(evaluation.latestSafeExitDateIfEnterToday)
    }

    func testNonHomeCountryDaysAreIgnored() {
        let engine = ResidencyEngine(calendar: utcCalendar)
        let asOf = Self.day("2026-03-14")

        let evaluation = engine.evaluate(
            asOf: asOf,
            homeCountryCode: "RU",
            rule: defaultRule,
            presenceDays: [
                ResidencyPresenceDay(date: Self.day("2026-03-14"), countryCode: "AE"),
                ResidencyPresenceDay(date: Self.day("2026-03-13"), countryCode: "FR"),
            ]
        )

        XCTAssertEqual(evaluation.daysUsed, 0)
        XCTAssertEqual(evaluation.daysRemaining, 182)
    }

    private static func day(_ isoDay: String) -> Date {
        ISO8601DateFormatter().date(from: "\(isoDay)T00:00:00Z")!
    }
}
