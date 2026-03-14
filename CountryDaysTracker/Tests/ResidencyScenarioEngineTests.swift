//
//  ResidencyScenarioEngineTests.swift
//
//  Created on 15 March 2026.
//

import XCTest
@testable import CountryDaysTracker

final class ResidencyScenarioEngineTests: XCTestCase {
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

    func testPlanStayReturnsSafeWindowForFutureArrival() {
        let engine = ResidencyScenarioEngine(calendar: utcCalendar)
        let arrivalDate = Self.day("2026-03-14")
        let exitDate = Self.day("2026-04-12")
        let presenceDays = (0..<100).map { offset in
            ResidencyPresenceDay(
                date: utcCalendar.date(byAdding: .day, value: -(offset + 1), to: arrivalDate)!,
                countryCode: "RU"
            )
        }

        let plan = engine.evaluateScenario(
            arrivalDate: arrivalDate,
            exitDate: exitDate,
            targetCountryCode: "RU",
            homeCountryCode: "RU",
            rule: defaultRule,
            presenceDays: presenceDays
        )

        XCTAssertTrue(plan.isScenarioSafe)
        XCTAssertTrue(plan.affectsHomeCountryDays)
        XCTAssertEqual(plan.maxSafeStayLengthDays, 82)
        XCTAssertNil(plan.breachDate)
        XCTAssertEqual(plan.latestSafeExitDateForScenario, Self.day("2026-06-03"))
        XCTAssertEqual(plan.projectedDaysUsedAfterScenario, 130)
        XCTAssertEqual(plan.projectedDaysRemainingAfterScenario, 52)
        XCTAssertEqual(plan.earliestSafeArrivalDateForRequestedStay, arrivalDate)
    }

    func testPlanStayReturnsUnsafeBoundaryAndDefersArrivalWhenNeeded() {
        let engine = ResidencyScenarioEngine(calendar: utcCalendar)
        let arrivalDate = Self.day("2026-03-14")
        let exitDate = Self.day("2026-03-20")
        let presenceDays = (0..<183).map { offset in
            ResidencyPresenceDay(
                date: utcCalendar.date(byAdding: .day, value: -(364 - offset), to: arrivalDate)!,
                countryCode: "RU"
            )
        }

        let plan = engine.evaluateScenario(
            arrivalDate: arrivalDate,
            exitDate: exitDate,
            targetCountryCode: "RU",
            homeCountryCode: "RU",
            rule: defaultRule,
            presenceDays: presenceDays
        )

        XCTAssertFalse(plan.isScenarioSafe)
        XCTAssertEqual(plan.maxSafeStayLengthDays, 0)
        XCTAssertEqual(plan.breachDate, arrivalDate)
        XCTAssertNil(plan.latestSafeExitDateForScenario)
        XCTAssertEqual(plan.earliestSafeArrivalDateForRequestedStay, Self.day("2026-03-16"))
    }

    func testNonHomeTripDoesNotAddResidencyDays() {
        let engine = ResidencyScenarioEngine(calendar: utcCalendar)
        let arrivalDate = Self.day("2026-03-14")
        let exitDate = Self.day("2026-03-20")
        let presenceDays = (0..<120).map { offset in
            ResidencyPresenceDay(
                date: utcCalendar.date(byAdding: .day, value: -(offset + 1), to: arrivalDate)!,
                countryCode: "RU"
            )
        }

        let plan = engine.evaluateScenario(
            arrivalDate: arrivalDate,
            exitDate: exitDate,
            targetCountryCode: "AE",
            homeCountryCode: "RU",
            rule: defaultRule,
            presenceDays: presenceDays
        )

        XCTAssertTrue(plan.isScenarioSafe)
        XCTAssertFalse(plan.affectsHomeCountryDays)
        XCTAssertNil(plan.latestSafeExitDateForScenario)
        XCTAssertEqual(plan.projectedDaysUsedAfterScenario, 120)
        XCTAssertEqual(plan.projectedDaysRemainingAfterScenario, 62)
        XCTAssertNil(plan.breachDate)
        XCTAssertEqual(plan.earliestSafeArrivalDateForRequestedStay, Self.day("2026-03-21"))
    }

    private static func day(_ isoDay: String) -> Date {
        ISO8601DateFormatter().date(from: "\(isoDay)T00:00:00Z")!
    }
}
