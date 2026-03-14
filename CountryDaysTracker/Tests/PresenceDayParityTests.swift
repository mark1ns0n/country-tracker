//
//  PresenceDayParityTests.swift
//
//  Created on 15 March 2026.
//

import XCTest
@testable import CountryDaysTracker

final class PresenceDayParityTests: XCTestCase {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testPresenceDayCountsMatchIntervalAggregation() {
        let range = Self.day("2026-03-10")...Self.day("2026-03-12")
        let intervals = [
            StayInterval(
                countryCode: "RU",
                entryAt: Self.timestamp("2026-03-10T00:30:00Z"),
                exitAt: Self.timestamp("2026-03-10T08:00:00Z"),
                source: "test",
                confidence: 1
            ),
            StayInterval(
                countryCode: "AE",
                entryAt: Self.timestamp("2026-03-10T09:00:00Z"),
                exitAt: Self.timestamp("2026-03-11T20:00:00Z"),
                source: "test",
                confidence: 1
            ),
            StayInterval(
                countryCode: "FR",
                entryAt: Self.timestamp("2026-03-12T10:00:00Z"),
                exitAt: Self.timestamp("2026-03-12T12:00:00Z"),
                source: "test",
                confidence: 1
            ),
        ]
        let aggregation = AggregationService(calendar: utcCalendar)
        let builder = PresenceDayBuilder(calendar: utcCalendar, nowProvider: { Self.timestamp("2026-03-12T12:00:00Z") })

        let intervalCounts = aggregation.daysByCountry(range: range, intervals: intervals)
        let intervalVisitedCountries = aggregation.visitedCountries(range: range, intervals: intervals)
        let intervalHomeCountryCount = intervalCounts["RU"] ?? 0

        let records = builder.build(from: intervals)
        let presenceCounts = Dictionary(grouping: records, by: \.countryCode).mapValues(\.count)
        let presenceVisitedCountries = Set(records.map(\.countryCode))
        let presenceHomeCountryCount = presenceCounts["RU"] ?? 0

        XCTAssertEqual(intervalCounts, presenceCounts)
        XCTAssertEqual(intervalVisitedCountries, presenceVisitedCountries)
        XCTAssertEqual(intervalHomeCountryCount, presenceHomeCountryCount)
    }

    private static func day(_ isoDay: String) -> Date {
        ISO8601DateFormatter().date(from: "\(isoDay)T00:00:00Z")!
    }

    private static func timestamp(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601)!
    }
}
