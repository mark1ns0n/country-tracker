//
//  StayEngineTests.swift
//
//  Created on 14 December 2025.
//

import XCTest
import SwiftData
@testable import CountryDaysTracker

final class StayEngineTests: XCTestCase {
    func makeRepo() -> StayRepository {
        let container = try! ModelContainer(for: StayInterval.self, LocationEventLog.self)
        let ctx = ModelContext(container)
        return StayRepository(modelContext: ctx)
    }
    
    func testCreateFirstInterval() async {
        let repo = makeRepo()
        let engine = StayEngine(repository: repo)
        
        XCTAssertNil(repo.fetchOpenInterval())
        await engine.processCountryUpdate(countryCode: "US", at: Date(), source: "test", confidence: 1.0)
        let open = repo.fetchOpenInterval()
        XCTAssertNotNil(open)
        XCTAssertEqual(open?.countryCode, "US")
    }
    
    func testSameCountryUpdateDoesNotClose() async {
        let repo = makeRepo()
        let engine = StayEngine(repository: repo)
        let now = Date()
        await engine.processCountryUpdate(countryCode: "US", at: now, source: "test", confidence: 1.0)
        await engine.processCountryUpdate(countryCode: "US", at: now.addingTimeInterval(60), source: "test", confidence: 1.0)
        let open = repo.fetchOpenInterval()
        XCTAssertNotNil(open)
        XCTAssertNil(open?.exitAt)
    }
    
    func testSwitchCountryClosesAndOpens() async {
        let repo = makeRepo()
        let engine = StayEngine(repository: repo)
        let t0 = Date()
        await engine.processCountryUpdate(countryCode: "US", at: t0, source: "test", confidence: 1.0)
        let t1 = t0.addingTimeInterval(3600)
        await engine.processCountryUpdate(countryCode: "FR", at: t1, source: "test", confidence: 1.0)
        
        // After switch, there should be an open FR interval
        let open = repo.fetchOpenInterval()
        XCTAssertEqual(open?.countryCode, "FR")
    }
}
