//
//  DayCellView.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI

struct DayCellView: View {
    let date: Date
    let result: DayCountryResult?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .secondarySystemBackground))
            VStack(spacing: 6) {
                if date == Date.distantPast {
                    Color.clear.frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(dayNumber(date))
                        .font(.body.monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let result = result, date != Date.distantPast {
                    switch result {
                    case .single(let code):
                        Text(emojiFlag(for: code))
                            .font(.title3)
                    case .mixed(let codes):
                        HStack(spacing: 4) {
                            ForEach(codes.prefix(2), id: \.self) { c in
                                Text(emojiFlag(for: c))
                                    .font(.headline)
                            }
                        }
                    case .unknown:
                        Text("—")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
        }
        .frame(height: 56)
    }
    
    private func dayNumber(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
    }
    
    private func emojiFlag(for isoCountryCode: String) -> String {
        let upper = isoCountryCode.uppercased()
        guard upper.count == 2 else { return "🏳️" }
        let base: UInt32 = 127397 // Regional Indicator Symbol Letter A
        var s = ""
        for scalar in upper.unicodeScalars {
            if let u = UnicodeScalar(base + scalar.value) {
                s.append(String(u))
            }
        }
        return s
    }
}
