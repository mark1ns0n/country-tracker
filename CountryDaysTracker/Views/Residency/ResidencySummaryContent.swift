//
//  ResidencySummaryContent.swift
//  CountryDaysTracker
//
//  Created on 15 March 2026.
//

import SwiftUI

enum ResidencySummaryFormatter {
    static func formattedDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

struct ResidencySummaryContent: View {
    let evaluation: ResidencyEvaluation
    let accentCountryCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(accentCountryCode)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("Rolling \(evaluation.windowLengthDays)-day window")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                metricCard(
                    title: "Used",
                    value: "\(evaluation.daysUsed)",
                    caption: "of \(evaluation.safeLimitDays) safe days"
                )
                metricCard(
                    title: "Left",
                    value: "\(evaluation.daysRemaining)",
                    caption: "days still safe"
                )
            }

            HStack(spacing: 12) {
                metricCard(
                    title: "Enter Today",
                    value: "\(evaluation.maxSafeStayIfEnterToday)d",
                    caption: "max continuous stay"
                )
                metricCard(
                    title: "Leave By",
                    value: ResidencySummaryFormatter.formattedDate(evaluation.latestSafeExitDateIfEnterToday),
                    caption: "latest safe exit"
                )
            }

            HStack(spacing: 12) {
                metricCard(
                    title: "Next Entry",
                    value: ResidencySummaryFormatter.formattedDate(evaluation.nextSafeEntryDate),
                    caption: "first safe return"
                )
                metricCard(
                    title: "Unsafe On",
                    value: ResidencySummaryFormatter.formattedDate(evaluation.breachDateIfStayFromToday),
                    caption: "first unsafe day"
                )
            }

            if let breachDate = evaluation.breachDateIfStayFromToday {
                Text("If you go home now and stay, the first unsafe day is \(ResidencySummaryFormatter.formattedDate(breachDate)).")
                    .font(.footnote)
                    .foregroundStyle(evaluation.daysRemaining == 0 ? .red : .secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func metricCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
