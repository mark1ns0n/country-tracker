//
//  RootTabView.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var locationService: LocationService
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarAndMapView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(0)
            
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
                .tag(1)
            
            SettingsViewContent(locationService: locationService)
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(2)
        }
    }
}

// MARK: - Placeholder Views

struct CalendarTabView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                Text("Calendar View")
                    .font(.title)
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Calendar")
        }
    }
}

struct MapTabView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "map")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                Text("Map View")
                    .font(.title)
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Map")
        }
    }
}

struct StatsTabView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "chart.bar")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                Text("Stats View")
                    .font(.title)
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Stats")
        }
    }
}

#Preview {
    RootTabView()
}
