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
            CalendarMonthView()
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

#Preview {
    RootTabView()
}
