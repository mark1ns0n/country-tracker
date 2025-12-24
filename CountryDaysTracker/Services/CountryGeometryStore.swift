//
//  CountryGeometryStore.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation
import MapKit

final class CountryGeometryStore {
    private(set) var polygonsByISO: [String: [MKPolygon]] = [:]
    
    init() {
        load()
    }
    
    private func load() {
        guard let url = Bundle.main.url(forResource: "world_countries_simplified", withExtension: "geojson") else {
            print("⚠️ GeoJSON resource not found")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = MKGeoJSONDecoder()
            let objects = try decoder.decode(data)
            let features = objects.compactMap { $0 as? MKGeoJSONFeature }
            print("🌐 Parsed features: \(features.count)")
            
            for feature in features {
                let isoCode = extractISOCode(from: feature.properties)
                let geos = feature.geometry
                let polys = geos.compactMap { $0 as? MKPolygon }
                if let code = isoCode, !polys.isEmpty {
                    polygonsByISO[code, default: []].append(contentsOf: polys)
                }
            }
            print("✅ Countries in index: \(polygonsByISO.count)")
        } catch {
            print("❌ Failed to parse GeoJSON: \(error)")
        }
    }
    
    private func extractISOCode(from data: Data?) -> String? {
        guard let data = data else { return nil }
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [])
            if let dict = obj as? [String: Any] {
                // Common property keys
                for key in ["ISO_A2", "iso_a2", "ISO2", "isoCountryCode", "countryCode"] {
                    if let val = dict[key] as? String, !val.isEmpty { return val.uppercased() }
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}
