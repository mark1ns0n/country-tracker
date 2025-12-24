//
//  ContentView.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("didOnboard") private var didOnboard = false
    @State private var showWelcome = true
    
    var body: some View {
        if !didOnboard {
            OnboardingFlow(didCompleteOnboarding: $didOnboard)
        } else {
            MainAppView()
        }
    }
}

struct OnboardingFlow: View {
    @Binding var didCompleteOnboarding: Bool
    @State private var showWelcome = true
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationService = LocationService.placeholder
    
    var body: some View {
        Group {
            if showWelcome {
                WelcomeView(showOnboarding: $showWelcome)
            } else {
                LocationPermissionView(
                    locationService: locationService,
                    didCompleteOnboarding: $didCompleteOnboarding
                )
            }
        }
        .onAppear { bootstrapIfNeeded() }
    }
    
    private func bootstrapIfNeeded() {
        // Replace placeholder with real service tied to shared modelContext
        if locationService.isPlaceholder {
            let repo = StayRepository(modelContext: modelContext)
            let engine = StayEngine(repository: repo)
            let real = LocationService(stayEngine: engine, repository: repo)
            locationService.adopt(from: real)
        }
    }
}

struct MainAppView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationService = LocationService.placeholder
    @Environment(\.scenePhase) private var scenePhase
    @State private var lastSync: Date? = nil
    
    var body: some View {
        RootTabView()
            .environmentObject(locationService)
            .onAppear {
                bootstrapIfNeeded()
                refreshWidgetStats()
                // Start location monitoring when app appears
                if locationService.authorizationStatus == .authorizedAlways ||
                   locationService.authorizationStatus == .authorizedWhenInUse {
                    locationService.start()
                    locationService.requestLocation() // seed immediate location
                }
            }
            .onChange(of: scenePhase) { phase in
                // Sync on app open with simple rate limit (15 minutes)
                if phase == .active {
                    bootstrapIfNeeded()
                    refreshWidgetStats()
                    let now = Date()
                    if lastSync == nil || now.timeIntervalSince(lastSync!) > 15 * 60 {
                        locationService.requestLocation()
                        lastSync = now
                    }
                }
            }
    }
    
    private func bootstrapIfNeeded() {
        if locationService.isPlaceholder {
            let repo = StayRepository(modelContext: modelContext)
            let engine = StayEngine(repository: repo)
            let real = LocationService(stayEngine: engine, repository: repo)
            locationService.adopt(from: real)
        }
    }
    
    private func refreshWidgetStats() {
        let repo = StayRepository(modelContext: modelContext)
        repo.refreshWidgetStatsForLastYear()
    }
}

#Preview {
    ContentView()
}
