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

private enum WidgetStatsDefaults {
    static let suiteName = "group.com.mark1ns0n.countrydaystracker"
    static let statsKey = "yearStatsWidget_v2"
}

final class WidgetDataService {
    static let shared = WidgetDataService()
    
    private init() {}
    
    func loadStats() -> CountryYearStats? {
        guard let data = UserDefaults(suiteName: WidgetStatsDefaults.suiteName)?
            .data(forKey: WidgetStatsDefaults.statsKey) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(CountryYearStats.self, from: data)
        } catch {
            print("Failed to decode widget stats: \(error)")
            return nil
        }
    }
}

private extension String {
    /// Convert ISO A2 country code to flag emoji
    func flagEmoji() -> String {
        let upper = self.uppercased()
        guard upper.count == 2 else { return "🏳️" }
        let base: UInt32 = 127397
        var result = ""
        for scalar in upper.unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                result.append(String(unicode))
            }
        }
        return result
    }
}

func flagEmoji(for iso: String) -> String {
    iso.flagEmoji()
}
