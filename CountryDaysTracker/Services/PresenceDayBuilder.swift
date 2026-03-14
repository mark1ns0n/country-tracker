//
//  PresenceDayBuilder.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation

struct PresenceDayRecord: Equatable, Hashable {
    let date: Date
    let countryCode: String
    let source: String
}

struct PresenceDayIdentity: Hashable {
    let date: Date
    let countryCode: String
}

struct PresenceDayBuilder {
    private let calendar: Calendar
    private let nowProvider: () -> Date

    init(
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = { Date() }
    ) {
        self.calendar = calendar
        self.nowProvider = nowProvider
    }

    func build(from intervals: [StayInterval]) -> [PresenceDayRecord] {
        let now = nowProvider()
        var uniqueRecords: [PresenceDayIdentity: PresenceDayRecord] = [:]

        for interval in intervals {
            let intervalEnd = normalizedEnd(for: interval, now: now)
            let range = DateUtils.startOfDay(interval.entryAt, calendar: calendar)...DateUtils.startOfDay(intervalEnd, calendar: calendar)

            for day in DateUtils.daysInRange(range, calendar: calendar) {
                let record = PresenceDayRecord(
                    date: day,
                    countryCode: interval.countryCode.uppercased(),
                    source: PresenceDay.derivedSource
                )
                uniqueRecords[PresenceDayIdentity(date: day, countryCode: record.countryCode)] = record
            }
        }

        return uniqueRecords.values.sorted { lhs, rhs in
            lhs.date == rhs.date ? lhs.countryCode < rhs.countryCode : lhs.date < rhs.date
        }
    }

    private func normalizedEnd(for interval: StayInterval, now: Date) -> Date {
        let intervalEnd = interval.exitAt ?? now
        return max(interval.entryAt, intervalEnd)
    }
}
