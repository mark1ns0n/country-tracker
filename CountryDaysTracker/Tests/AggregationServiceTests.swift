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
}
