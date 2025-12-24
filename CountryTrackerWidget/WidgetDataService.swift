//
//  WidgetDataService.swift
//  CountryTrackerWidget
//
//  Created on 18 December 2025.
//

import Foundation

struct CountryYearStats: Codable {
    let countriesCount: Int
    let totalDays: Int
    let tripsCount: Int
    let topCountries: [CountryData]
    let lastUpdated: Date
}

struct CountryData: Codable, Identifiable {
    let id: String
    let code: String
    let days: Int
    
    enum CodingKeys: String, CodingKey {
        case code
        case days
    }
    
    init(code: String, days: Int) {
        self.id = code
        self.code = code
        self.days = days
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        days = try container.decode(Int.self, forKey: .days)
        id = code
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(days, forKey: .days)
    }
}

class WidgetDataService {
    static let shared = WidgetDataService()
    private let userDefaults = UserDefaults(suiteName: "group.com.mark1ns0n.countrydaystracker")
    private let statsKey = "yearStatsWidget"
    
    func saveStats(_ stats: CountryYearStats) {
        do {
            let data = try JSONEncoder().encode(stats)
            userDefaults?.set(data, forKey: statsKey)
        } catch {
            print("Failed to save widget stats: \(error)")
        }
    }
    
    func loadStats() -> CountryYearStats? {
        guard let data = userDefaults?.data(forKey: statsKey) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(CountryYearStats.self, from: data)
        } catch {
            print("Failed to load widget stats: \(error)")
            return nil
        }
    }
}
