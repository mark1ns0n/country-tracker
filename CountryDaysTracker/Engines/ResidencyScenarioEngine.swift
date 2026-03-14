//
//  ResidencyScenarioEngine.swift
//  CountryDaysTracker
//
//  Created on 15 March 2026.
//

import Foundation

struct ResidencyStayPlan: Equatable {
    let arrivalDate: Date
    let exitDate: Date
    let targetCountryCode: String
    let homeCountryCode: String
    let requestedStayLengthDays: Int
    let maxSafeStayLengthDays: Int
    let isScenarioSafe: Bool
    let affectsHomeCountryDays: Bool
    let breachDate: Date?
    let latestSafeExitDateForScenario: Date?
    let projectedDaysUsedAfterScenario: Int
    let projectedDaysRemainingAfterScenario: Int
    let earliestSafeArrivalDateForRequestedStay: Date?
}

struct ResidencyScenarioEngine {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Assumption: arrival and exit dates are inclusive calendar days. A same-day trip counts
    /// as one day. Only trips to the configured home country add residency-risk days.
    func evaluateScenario(
        arrivalDate: Date,
        exitDate: Date,
        targetCountryCode: String,
        homeCountryCode: String,
        rule: ResidencyRuleConfiguration,
        presenceDays: [ResidencyPresenceDay]
    ) -> ResidencyStayPlan {
        let normalizedArrivalDate = DateUtils.startOfDay(arrivalDate, calendar: calendar)
        let normalizedExitDate = max(
            normalizedArrivalDate,
            DateUtils.startOfDay(exitDate, calendar: calendar)
        )
        let normalizedHomeCountry = homeCountryCode.uppercased()
        let normalizedTargetCountry = targetCountryCode.uppercased()
        let homeDates = ResidencyHomeCountryDaySet.make(
            presenceDays: presenceDays,
            homeCountryCode: normalizedHomeCountry,
            calendar: calendar
        )
        let requestedLength = requestedStayLengthDays(
            arrivalDate: normalizedArrivalDate,
            exitDate: normalizedExitDate
        )
        let calculator = ResidencyRollingWindowCalculator(
            calendar: calendar,
            rule: rule,
            homeDates: homeDates
        )
        let (firstUnsafeDateForHomeTrip, maxSafeStayLengthDays) = calculator.breachOutcomeIfStayingContinuously(
            startingAt: normalizedArrivalDate
        )
        let affectsHomeCountryDays = normalizedTargetCountry == normalizedHomeCountry
        let requestedStayDates = affectsHomeCountryDays ? calculator.continuousStayDates(
            startingAt: normalizedArrivalDate,
            lengthDays: requestedLength
        ) : Set<Date>()
        let projectedDaysUsedAfterScenario = calculator.rollingCount(
            endingAt: normalizedExitDate,
            addedStayDates: requestedStayDates
        )
        let projectedDaysRemainingAfterScenario = max(
            0,
            rule.safeLimitDays - projectedDaysUsedAfterScenario
        )
        let breachDate: Date? = if affectsHomeCountryDays,
                            let firstUnsafeDateForHomeTrip,
                            firstUnsafeDateForHomeTrip <= normalizedExitDate {
            firstUnsafeDateForHomeTrip
        } else {
            nil
        }
        let latestSafeExitDateForScenario = affectsHomeCountryDays
            ? calculator.latestSafeExitDate(
                startingAt: normalizedArrivalDate,
                safeStayLengthDays: maxSafeStayLengthDays
            )
            : nil
        let earliestSafeArrivalSearchStart = affectsHomeCountryDays
            ? normalizedArrivalDate
            : (calendar.date(byAdding: .day, value: 1, to: normalizedExitDate) ?? normalizedExitDate)
        let earliestSafeArrivalDateForRequestedStay = calculator.earliestSafeArrivalDate(
            forContinuousStayLength: requestedLength,
            startingAt: earliestSafeArrivalSearchStart
        )

        return ResidencyStayPlan(
            arrivalDate: normalizedArrivalDate,
            exitDate: normalizedExitDate,
            targetCountryCode: normalizedTargetCountry,
            homeCountryCode: normalizedHomeCountry,
            requestedStayLengthDays: requestedLength,
            maxSafeStayLengthDays: maxSafeStayLengthDays,
            isScenarioSafe: breachDate == nil,
            affectsHomeCountryDays: affectsHomeCountryDays,
            breachDate: breachDate,
            latestSafeExitDateForScenario: latestSafeExitDateForScenario,
            projectedDaysUsedAfterScenario: projectedDaysUsedAfterScenario,
            projectedDaysRemainingAfterScenario: projectedDaysRemainingAfterScenario,
            earliestSafeArrivalDateForRequestedStay: earliestSafeArrivalDateForRequestedStay
        )
    }

    private func requestedStayLengthDays(
        arrivalDate: Date,
        exitDate: Date
    ) -> Int {
        let components = calendar.dateComponents([.day], from: arrivalDate, to: exitDate)
        return max(1, (components.day ?? 0) + 1)
    }
}
