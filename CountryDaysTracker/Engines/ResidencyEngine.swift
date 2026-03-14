//
//  ResidencyEngine.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation

struct ResidencyRuleConfiguration: Equatable {
    let identifier: String
    let title: String
    let jurisdictionCode: String
    let windowKind: String
    let windowLengthDays: Int
    let thresholdDays: Int
    let safeLimitDays: Int
}

struct ResidencyPresenceDay: Hashable {
    let date: Date
    let countryCode: String
}

struct ResidencyEvaluation: Equatable {
    let asOfDate: Date
    let homeCountryCode: String
    let ruleTitle: String
    let windowLengthDays: Int
    let daysUsed: Int
    let daysRemaining: Int
    let thresholdDays: Int
    let safeLimitDays: Int
    let isThresholdExceeded: Bool
    let breachDateIfStayFromToday: Date?
    let latestSafeExitDateIfEnterToday: Date?
    let nextSafeEntryDate: Date?
    let maxSafeStayIfEnterToday: Int
}

struct ResidencyEngine {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Assumption: residency counting is done on local calendar days. A day counts if at
    /// least one `PresenceDay` exists for the home country on that date. Rolling windows
    /// are inclusive and contain exactly `windowLengthDays` calendar days ending at `asOf`.
    func evaluate(
        asOf: Date,
        homeCountryCode: String,
        rule: ResidencyRuleConfiguration,
        presenceDays: [ResidencyPresenceDay]
    ) -> ResidencyEvaluation {
        let asOfDay = DateUtils.startOfDay(asOf, calendar: calendar)
        let normalizedHomeCountry = homeCountryCode.uppercased()
        let homeDates = ResidencyHomeCountryDaySet.make(
            presenceDays: presenceDays,
            homeCountryCode: normalizedHomeCountry,
            calendar: calendar
        )
        let calculator = ResidencyRollingWindowCalculator(
            calendar: calendar,
            rule: rule,
            homeDates: homeDates
        )

        let daysUsed = calculator.rollingCount(endingAt: asOfDay)
        let daysRemaining = max(0, rule.safeLimitDays - daysUsed)
        let isThresholdExceeded = daysUsed >= rule.thresholdDays
        let nextSafeEntryDate = calculator.earliestSafeEntryDate(startingAt: asOfDay)
        let (breachDateIfStayFromToday, maxSafeStayIfEnterToday) = calculator.breachOutcomeIfStayingContinuously(
            startingAt: asOfDay
        )
        let latestSafeExitDateIfEnterToday = calculator.latestSafeExitDate(
            startingAt: asOfDay,
            safeStayLengthDays: maxSafeStayIfEnterToday
        )

        return ResidencyEvaluation(
            asOfDate: asOfDay,
            homeCountryCode: normalizedHomeCountry,
            ruleTitle: rule.title,
            windowLengthDays: rule.windowLengthDays,
            daysUsed: daysUsed,
            daysRemaining: daysRemaining,
            thresholdDays: rule.thresholdDays,
            safeLimitDays: rule.safeLimitDays,
            isThresholdExceeded: isThresholdExceeded,
            breachDateIfStayFromToday: breachDateIfStayFromToday,
            latestSafeExitDateIfEnterToday: latestSafeExitDateIfEnterToday,
            nextSafeEntryDate: nextSafeEntryDate,
            maxSafeStayIfEnterToday: maxSafeStayIfEnterToday
        )
    }
}

enum ResidencyHomeCountryDaySet {
    static func make(
        presenceDays: [ResidencyPresenceDay],
        homeCountryCode: String,
        calendar: Calendar
    ) -> Set<Date> {
        Set(
            presenceDays
                .filter { $0.countryCode.uppercased() == homeCountryCode.uppercased() }
                .map { DateUtils.startOfDay($0.date, calendar: calendar) }
        )
    }
}

struct ResidencyRollingWindowCalculator {
    let calendar: Calendar
    let rule: ResidencyRuleConfiguration
    let homeDates: Set<Date>

    func rollingCount(
        endingAt day: Date,
        addedStayDates: Set<Date> = []
    ) -> Int {
        let range = rollingRange(endingAt: day, lengthDays: rule.windowLengthDays)
        return homeDates.union(addedStayDates).filter { range.contains($0) }.count
    }

    func earliestSafeEntryDate(startingAt day: Date) -> Date? {
        for offset in 0...(rule.windowLengthDays * 2) {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: day) else { continue }
            let countIfEntering = rollingCount(
                endingAt: candidate,
                addedStayDates: Set([candidate])
            )
            if countIfEntering <= rule.safeLimitDays {
                return candidate
            }
        }

        return nil
    }

    func breachOutcomeIfStayingContinuously(
        startingAt day: Date
    ) -> (Date?, Int) {
        var addedStayDates: Set<Date> = []

        for offset in 0...rule.windowLengthDays {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: day) else { continue }
            addedStayDates.insert(candidate)

            let count = rollingCount(
                endingAt: candidate,
                addedStayDates: addedStayDates
            )

            if count > rule.safeLimitDays {
                return (candidate, offset)
            }
        }

        return (nil, rule.windowLengthDays)
    }

    func earliestSafeArrivalDate(
        forContinuousStayLength lengthDays: Int,
        startingAt day: Date
    ) -> Date? {
        let searchHorizon = max(rule.windowLengthDays * 3, lengthDays + rule.windowLengthDays)

        for offset in 0...searchHorizon {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: day) else { continue }
            let (_, maxSafeStayLengthDays) = breachOutcomeIfStayingContinuously(
                startingAt: candidate
            )

            if maxSafeStayLengthDays >= lengthDays {
                return candidate
            }
        }

        return nil
    }

    func continuousStayDates(
        startingAt day: Date,
        lengthDays: Int
    ) -> Set<Date> {
        let normalizedLength = max(1, lengthDays)
        var dates: Set<Date> = []

        for offset in 0..<normalizedLength {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: day) else { continue }
            dates.insert(candidate)
        }

        return dates
    }

    func latestSafeExitDate(
        startingAt day: Date,
        safeStayLengthDays: Int
    ) -> Date? {
        guard safeStayLengthDays > 0 else { return nil }
        return calendar.date(byAdding: .day, value: safeStayLengthDays - 1, to: day)
    }

    private func rollingRange(endingAt day: Date, lengthDays: Int) -> ClosedRange<Date> {
        let start = calendar.date(byAdding: .day, value: -(lengthDays - 1), to: day) ?? day
        return DateUtils.startOfDay(start, calendar: calendar)...DateUtils.startOfDay(day, calendar: calendar)
    }
}
