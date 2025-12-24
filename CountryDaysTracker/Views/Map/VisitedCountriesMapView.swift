//
//  VisitedCountriesMapView.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI
import MapKit
import SwiftData

struct VisitedCountriesMapView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var rangeVM = RangeSelectionViewModel()
    @State private var overlays: [MKOverlay] = []
    
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
            
            MapRepresentable(overlays: overlays)
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
        
        let geometry = CountryGeometryStore()
        var newOverlays: [MKOverlay] = []
        for code in visited {
            if let polys = geometry.polygonsByISO[code] {
                newOverlays.append(contentsOf: polys)
            }
        }
        overlays = newOverlays
    }
}

struct MapRepresentable: UIViewRepresentable {
    let overlays: [MKOverlay]
    
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.mapType = .mutedStandard
        map.isRotateEnabled = false
        return map
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.addOverlays(overlays)
        
        if let first = overlays.first as? MKPolygon {
            uiView.setVisibleMapRect(first.boundingMapRect, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolygon {
                let r = MKPolygonRenderer(polygon: poly)
                r.fillColor = UIColor.systemBlue.withAlphaComponent(0.25)
                r.strokeColor = UIColor.systemBlue
                r.lineWidth = 1
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#Preview {
    VisitedCountriesMapView()
}
