//
//  AggregationServiceTests.swift
//
//  Created on 14 December 2025.
//

import XCTest
import SwiftData
@testable import CountryDaysTracker

final class AggregationServiceTests: XCTestCase {
    func makeIntervals() -> [StayInterval] {
        let now = Date()
        let d0 = Calendar.current.startOfDay(for: now.addingTimeInterval(-2*24*3600))
        let d1 = Calendar.current.startOfDay(for: now.addingTimeInterval(-1*24*3600))
        let d2 = Calendar.current.startOfDay(for: now)
        
        return [
            StayInterval(countryCode: "US", entryAt: d0, exitAt: d1.addingTimeInterval(-1), source: "test", confidence: 1.0),
            StayInterval(countryCode: "FR", entryAt: d1, exitAt: d2.addingTimeInterval(-1), source: "test", confidence: 1.0),
            StayInterval(countryCode: "FR", entryAt: d2, exitAt: nil, source: "test", confidence: 1.0)
        ]
    }
    
    func testSingleCountryForDay() {
        let svc = AggregationService()
        let intervals = makeIntervals()
        let day = Calendar.current.startOfDay(for: Date().addingTimeInterval(-24*3600))
        let res = svc.countryForDay(day, intervals: intervals)
        switch res {
        case .single(let code):
            XCTAssertEqual(code, "FR")
        default:
            XCTFail("Expected single country")
        }
    }
    
    func testMixedDay() {
        let svc = AggregationService()
        let intervals = [
            StayInterval(countryCode: "US", entryAt: Date().addingTimeInterval(-3600), exitAt: nil, source: "test", confidence: 1.0),
            StayInterval(countryCode: "FR", entryAt: Date().addingTimeInterval(-1800), exitAt: nil, source: "test", confidence: 1.0),
        ]
        let res = svc.countryForDay(Date(), intervals: intervals)
        if case .mixed(let codes) = res {
            XCTAssertTrue(codes.contains("US") && codes.contains("FR"))
        } else {
            XCTFail("Expected mixed day")
        }
    }
    
    func testVisitedCountries() {
        let svc = AggregationService()
        let intervals = makeIntervals()
        let now = Date()
        let range = now.addingTimeInterval(-3*24*3600)...now
        let set = svc.visitedCountries(range: range, intervals: intervals)
        XCTAssertTrue(set.contains("US") && set.contains("FR"))
    }

    func testDaysByCountryUsesDominantCountry() {
        let calendar = Calendar(identifier: .gregorian)
        let svc = AggregationService(calendar: calendar)

        let day = calendar.startOfDay(for: Date().addingTimeInterval(-24*3600))
        let morning = calendar.date(byAdding: .hour, value: 6, to: day)!
        let noon = calendar.date(byAdding: .hour, value: 12, to: day)!
        let night = calendar.date(byAdding: .hour, value: 23, to: day)!

        let intervals = [
            StayInterval(countryCode: "AE", entryAt: morning, exitAt: noon, source: "test", confidence: 1.0),
            StayInterval(countryCode: "RU", entryAt: noon, exitAt: night, source: "test", confidence: 1.0)
        ]

        let range = DateUtils.startOfDay(day, calendar: calendar)...DateUtils.endOfDay(day, calendar: calendar)
        let result = svc.daysByCountry(range: range, intervals: intervals)

        XCTAssertEqual(result["RU"], 1, "Country with longer overlap should win the day")
        XCTAssertNil(result["AE"], "Secondary country should not be double-counted for the same day")
        XCTAssertEqual(result.values.reduce(0, +), 1)
    }

    func testDaysByCountryBreaksTiesDeterministically() {
        let calendar = Calendar(identifier: .gregorian)
        let svc = AggregationService(calendar: calendar)

        let day = calendar.startOfDay(for: Date().addingTimeInterval(-48*3600))
        let morning = calendar.date(byAdding: .hour, value: 0, to: day)!
        let midday = calendar.date(byAdding: .hour, value: 12, to: day)!
        let endOfDay = calendar.date(byAdding: .hour, value: 23, to: day)!

        // Equal half-day splits between AE and RU
        let intervals = [
            StayInterval(countryCode: "AE", entryAt: morning, exitAt: midday, source: "test", confidence: 1.0),
            StayInterval(countryCode: "RU", entryAt: midday, exitAt: endOfDay, source: "test", confidence: 1.0)
        ]

        let range = DateUtils.startOfDay(day, calendar: calendar)...DateUtils.endOfDay(day, calendar: calendar)
        let result = svc.daysByCountry(range: range, intervals: intervals)

        XCTAssertEqual(result["AE"], 1, "Alphabetical order should break ties consistently")
        XCTAssertNil(result["RU"])
        XCTAssertEqual(result.values.reduce(0, +), 1)
    }

    func testDaysByCountryMatchesUniqueCount() {
        let calendar = Calendar(identifier: .gregorian)
        let svc = AggregationService(calendar: calendar)

        let day0 = calendar.startOfDay(for: Date().addingTimeInterval(-3*24*3600))
        let day1 = calendar.date(byAdding: .day, value: 1, to: day0)!
        let day2 = calendar.date(byAdding: .day, value: 2, to: day0)!

        // Day0: equal split -> AE wins alphabetically
        let intervals = [
            StayInterval(countryCode: "AE", entryAt: day0, exitAt: calendar.date(byAdding: .hour, value: 12, to: day0), source: "test", confidence: 1.0),
            StayInterval(countryCode: "RU", entryAt: calendar.date(byAdding: .hour, value: 12, to: day0)!, exitAt: calendar.date(byAdding: .hour, value: 23, to: day0), source: "test", confidence: 1.0),
            // Day1: full AE
            StayInterval(countryCode: "AE", entryAt: day1, exitAt: calendar.date(byAdding: .hour, value: 23, to: day1), source: "test", confidence: 1.0),
            // Day2: full RU
            StayInterval(countryCode: "RU", entryAt: day2, exitAt: calendar.date(byAdding: .hour, value: 23, to: day2), source: "test", confidence: 1.0)
        ]

        let range = DateUtils.startOfDay(day0, calendar: calendar)...DateUtils.endOfDay(day2, calendar: calendar)
        let byCountry = svc.daysByCountry(range: range, intervals: intervals)
        let unique = svc.uniqueDaysWithCountry(range: range, intervals: intervals)

        XCTAssertEqual(unique, 3)
        XCTAssertEqual(byCountry.values.reduce(0, +), 3)
    }
}
