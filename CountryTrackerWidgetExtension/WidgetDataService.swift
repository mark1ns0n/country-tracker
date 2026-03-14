import Foundation

final class WidgetDataService {
    static let shared = WidgetDataService()

    private init() {}

    func loadSnapshot() -> ResidencyWidgetSnapshot? {
        let defaults = UserDefaults(suiteName: ResidencyWidgetStore.suiteName)
        guard let data = defaults?.data(forKey: ResidencyWidgetStore.snapshotKey) else { return nil }

        do {
            return try JSONDecoder().decode(ResidencyWidgetSnapshot.self, from: data)
        } catch {
            print("Failed to decode residency widget snapshot: \(error)")
            return nil
        }
    }
}

private extension String {
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
