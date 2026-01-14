//
//  VisitedCountriesMapView.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI
import WebKit
import SwiftData

struct VisitedCountriesMapView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var rangeVM = RangeSelectionViewModel()
    @State private var visitedCountries: Set<String> = []
    
    var body: some View {
        VStack(spacing: 8) {
            // Range picker
            Picker("Range", selection: $rangeVM.preset) {
                ForEach(RangePreset.allCases) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            MapWebView(visitedCountries: visitedCountries)
                .onChange(of: rangeVM.preset) { _ in refresh() }
        }
        .navigationTitle("Visited Countries")
        .onAppear { refresh() }
    }
    
    private func refresh() {
        let repo = StayRepository(modelContext: modelContext)
        let intervals = repo.fetchIntervals(in: rangeVM.range)
        let agg = AggregationService()
        let visited = agg.visitedCountries(range: rangeVM.range, intervals: intervals)
        print("DEBUG: Refresh - visited countries: \(visited)")
        visitedCountries = visited.isEmpty ? ["US", "GB", "FR"] : visited // Test data if empty
    }
}

// MARK: - WebView for map
struct MapWebView: UIViewRepresentable {
    let visitedCountries: Set<String>
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let countryCodes = Array(visitedCountries)
        print("DEBUG: Loading map with countries: \(countryCodes)")
        let html = htmlContent(highlightedCountries: countryCodes)
        uiView.loadHTMLString(html, baseURL: nil)
    }
    
    private func htmlContent(highlightedCountries: [String]) -> String {
        let codesJson = highlightedCountries.map { "'\($0)'" }.joined(separator: ",")
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
            <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
            <style>
                body { margin: 0; padding: 0; font-family: Arial; }
                #map { position: absolute; top: 0; bottom: 0; width: 100%; }
                #debug { position: absolute; bottom: 10px; right: 10px; background: rgba(0,0,0,0.8); 
                         color: #00ff00; padding: 15px; font-size: 12px; max-width: 300px; z-index: 1000; }
            </style>
        </head>
        <body>
            <div id="map"></div>
            <div id="debug">Loading...</div>
            <script>
                const highlightedCodes = [\(codesJson)];
                console.log('=== MAP INIT ===');
                console.log('Target codes:', highlightedCodes);
                updateDebug('Target: ' + highlightedCodes.join(', '));
                
                function updateDebug(msg) {
                    console.log(msg);
                    document.getElementById('debug').innerHTML += '<br>' + msg;
                }
                
                const map = L.map('map').setView([20, 0], 2);
                updateDebug('Map created');
                
                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '© OpenStreetMap'
                }).addTo(map);
                updateDebug('Tiles added');
                
                // Simple test data
                const testData = {
                    "type": "FeatureCollection",
                    "features": [
                        {
                            "type": "Feature",
                            "properties": {"ISO_A2": "US", "name": "United States"},
                            "geometry": {"type": "Polygon", "coordinates": [[[-125, 25], [-125, 49], [-66, 49], [-66, 25], [-125, 25]]]}
                        },
                        {
                            "type": "Feature", 
                            "properties": {"ISO_A2": "GB", "name": "United Kingdom"},
                            "geometry": {"type": "Polygon", "coordinates": [[[-8, 50], [-8, 59], [2, 59], [2, 50], [-8, 50]]]}
                        },
                        {
                            "type": "Feature",
                            "properties": {"ISO_A2": "FR", "name": "France"},
                            "geometry": {"type": "Polygon", "coordinates": [[[−8, 41], [−8, 51], [8, 51], [8, 41], [−8, 41]]]}
                        }
                    ]
                };
                
                updateDebug('Test data ready');
                
                let highlightCount = 0;
                L.geoJSON(testData, {
                    style: function(feature) {
                        const code = feature.properties.ISO_A2;
                        const isHighlighted = highlightedCodes.includes(code);
                        if (isHighlighted) highlightCount++;
                        
                        return {
                            fillColor: isHighlighted ? '#007AFF' : '#ddd',
                            color: isHighlighted ? '#0051D5' : '#999',
                            weight: isHighlighted ? 3 : 1,
                            opacity: 1,
                            fillOpacity: isHighlighted ? 0.7 : 0.3
                        };
                    }
                }).addTo(map);
                
                updateDebug('Highlighted: ' + highlightCount + ' countries');
            </script>
        </body>
        </html>
        """
    }
}

#Preview {
    VisitedCountriesMapView()
}

#Preview {
    VisitedCountriesMapView()
}
