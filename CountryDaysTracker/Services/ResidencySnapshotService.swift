//
//  ResidencySnapshotService.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation
import SwiftData

@MainActor
final class ResidencySnapshotService {
    private let modelContext: ModelContext
    private let engine: ResidencyEngine
    private let scenarioEngine: ResidencyScenarioEngine

    init(
        modelContext: ModelContext,
        engine: ResidencyEngine = ResidencyEngine(),
        scenarioEngine: ResidencyScenarioEngine = ResidencyScenarioEngine()
    ) {
        self.modelContext = modelContext
        self.engine = engine
        self.scenarioEngine = scenarioEngine
    }

    func currentEvaluation(asOf: Date = Date()) throws -> ResidencyEvaluation {
        let context = try loadContext()

        return engine.evaluate(
            asOf: asOf,
            homeCountryCode: context.profile.homeCountryCode,
            rule: context.ruleConfiguration,
            presenceDays: context.presenceDays
        )
    }

    func planStay(
        arrivalDate: Date,
        exitDate: Date,
        targetCountryCode: String
    ) throws -> ResidencyStayPlan {
        let context = try loadContext()

        return scenarioEngine.evaluateScenario(
            arrivalDate: arrivalDate,
            exitDate: exitDate,
            targetCountryCode: targetCountryCode,
            homeCountryCode: context.profile.homeCountryCode,
            rule: context.ruleConfiguration,
            presenceDays: context.presenceDays
        )
    }

    private func loadContext() throws -> ResidencySnapshotContext {
        let settingsRepository = ResidencySettingsRepository(modelContext: modelContext)
        let profile = try settingsRepository.ensureDefaults()
        let ruleIdentifier = profile.activeRuleIdentifier ?? ResidencySettingsRepository.defaultRuleIdentifier

        guard let rule = try settingsRepository.fetchRule(identifier: ruleIdentifier) else {
            throw ResidencySnapshotError.activeRuleMissing
        }

        let presenceDays = try modelContext.fetch(FetchDescriptor<PresenceDay>())
        let ruleConfiguration = ResidencyRuleConfiguration(
            identifier: rule.identifier,
            title: rule.title,
            jurisdictionCode: rule.jurisdictionCode,
            windowKind: rule.windowKind,
            windowLengthDays: rule.windowLengthDays,
            thresholdDays: rule.thresholdDays,
            safeLimitDays: rule.safeLimitDays
        )

        let values = presenceDays.map {
            ResidencyPresenceDay(date: $0.date, countryCode: $0.countryCode)
        }

        return ResidencySnapshotContext(
            profile: profile,
            ruleConfiguration: ruleConfiguration,
            presenceDays: values
        )
    }
}

enum ResidencySnapshotError: Error {
    case activeRuleMissing
}

private struct ResidencySnapshotContext {
    let profile: ResidencyProfile
    let ruleConfiguration: ResidencyRuleConfiguration
    let presenceDays: [ResidencyPresenceDay]
}
