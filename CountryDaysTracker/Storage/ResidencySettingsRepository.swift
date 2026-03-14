//
//  ResidencySettingsRepository.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation
import SwiftData

struct ResidencyRuleOption: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
}

@MainActor
final class ResidencySettingsRepository {
    static let defaultRuleIdentifier = "ru-183-rolling-365"
    static let defaultHomeCountryCode = "RU"

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func ensureDefaults() throws -> ResidencyProfile {
        let rule = if let existingRule = try fetchRule(identifier: Self.defaultRuleIdentifier) {
            existingRule
        } else {
            try insertDefaultRule()
        }

        let profile = if let existingProfile = try fetchProfile() {
            existingProfile
        } else {
            try insertDefaultProfile(activeRuleIdentifier: rule.identifier)
        }

        let activeRuleIdentifier = profile.activeRuleIdentifier ?? ""
        let activeRuleExists = try fetchRule(identifier: activeRuleIdentifier) != nil

        if profile.activeRuleIdentifier == nil || !activeRuleExists {
            profile.activeRuleIdentifier = rule.identifier
            profile.updatedAt = Date()
            try modelContext.save()
        }

        return profile
    }

    func fetchProfile() throws -> ResidencyProfile? {
        var descriptor = FetchDescriptor<ResidencyProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func fetchRules() throws -> [ResidencyRule] {
        let descriptor = FetchDescriptor<ResidencyRule>(
            sortBy: [
                SortDescriptor(\.jurisdictionCode, order: .forward),
                SortDescriptor(\.title, order: .forward),
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRule(identifier: String) throws -> ResidencyRule? {
        let descriptor = FetchDescriptor<ResidencyRule>(
            predicate: #Predicate { $0.identifier == identifier }
        )
        return try modelContext.fetch(descriptor).first
    }

    func updateHomeCountryCode(_ code: String) throws {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard isValidCountryCode(normalized) else { return }

        let profile = try ensureDefaults()
        guard profile.homeCountryCode != normalized else { return }

        profile.homeCountryCode = normalized
        profile.updatedAt = Date()
        try modelContext.save()
    }

    func activateRule(identifier: String) throws {
        guard try fetchRule(identifier: identifier) != nil else { return }

        let profile = try ensureDefaults()
        guard profile.activeRuleIdentifier != identifier else { return }

        profile.activeRuleIdentifier = identifier
        profile.updatedAt = Date()
        try modelContext.save()
    }

    func fetchRuleOptions() throws -> [ResidencyRuleOption] {
        try fetchRules().map { rule in
            ResidencyRuleOption(
                id: rule.identifier,
                title: rule.title,
                subtitle: "\(rule.thresholdDays) days in \(rule.windowLengthDays)-day rolling window"
            )
        }
    }

    private func insertDefaultRule() throws -> ResidencyRule {
        let rule = ResidencyRule(
            identifier: Self.defaultRuleIdentifier,
            jurisdictionCode: "RU",
            windowLengthDays: 365,
            thresholdDays: 183,
            safeLimitDays: 182,
            title: "Russia: 183 days in 365-day window"
        )
        modelContext.insert(rule)
        try modelContext.save()
        return rule
    }

    private func insertDefaultProfile(activeRuleIdentifier: String) throws -> ResidencyProfile {
        let profile = ResidencyProfile(
            homeCountryCode: Self.defaultHomeCountryCode,
            activeRuleIdentifier: activeRuleIdentifier
        )
        modelContext.insert(profile)
        try modelContext.save()
        return profile
    }

    private func isValidCountryCode(_ code: String) -> Bool {
        code.range(of: "^[A-Z]{2}$", options: .regularExpression) != nil
    }
}
