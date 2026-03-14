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
            ResidencyDashboardView()
                .tabItem { Label("Residency", systemImage: "house.badge.exclamationmark") }
                .tag(0)

            CalendarMonthView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(1)
            
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
                .tag(2)
            
            SettingsViewContent(locationService: locationService)
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(LocationService.placeholder)
}
