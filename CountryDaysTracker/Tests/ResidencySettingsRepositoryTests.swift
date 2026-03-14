//
//  ResidencySettingsRepositoryTests.swift
//
//  Created on 14 March 2026.
//

import XCTest
import SwiftData
@testable import CountryDaysTracker

@MainActor
final class ResidencySettingsRepositoryTests: XCTestCase {
    private func makeRepository() -> ResidencySettingsRepository {
        let container = try! AppModelSchema.makeContainer(inMemory: true)
        let context = ModelContext(container)
        return ResidencySettingsRepository(modelContext: context)
    }

    func testEnsureDefaultsCreatesOneProfileAndOneRule() throws {
        let repository = makeRepository()

        let profile = try repository.ensureDefaults()
        let rules = try repository.fetchRules()

        XCTAssertEqual(profile.homeCountryCode, "RU")
        XCTAssertEqual(profile.activeRuleIdentifier, ResidencySettingsRepository.defaultRuleIdentifier)
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.identifier, ResidencySettingsRepository.defaultRuleIdentifier)
    }

    func testEnsureDefaultsIsIdempotent() throws {
        let repository = makeRepository()

        _ = try repository.ensureDefaults()
        _ = try repository.ensureDefaults()

        let profile = try repository.fetchProfile()
        let rules = try repository.fetchRules()

        XCTAssertNotNil(profile)
        XCTAssertEqual(rules.count, 1)
    }

    func testUpdateHomeCountryUppercasesValue() throws {
        let repository = makeRepository()

        _ = try repository.ensureDefaults()
        try repository.updateHomeCountryCode("ae")

        let profile = try repository.fetchProfile()
        XCTAssertEqual(profile?.homeCountryCode, "AE")
    }
}
