//
//  SettingsView.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI
import SwiftData
import CoreLocation

struct SettingsViewContent: View {
    @ObservedObject var locationService: LocationService
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List {
                // Location Permission Section
                Section("Location") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(authorizationStatusText)
                            .foregroundStyle(authorizationStatusColor)
                    }
                    
                    if locationService.authorizationStatus != .authorizedAlways {
                        Button("Open System Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Monitoring")
                        Spacer()
                        Text(locationService.isMonitoring ? "Active" : "Inactive")
                            .foregroundStyle(locationService.isMonitoring ? .green : .gray)
                    }
                }
                
                // Debug Section (only in DEBUG builds)
                #if DEBUG
                Section("Debug") {
                    NavigationLink("View Logs") { LogsView() }
                    
                    Button("Reset Onboarding", role: .destructive) {
                        UserDefaults.standard.set(false, forKey: "didOnboard")
                    }
                }
                #endif
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private var authorizationStatusText: String {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "When In Use"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var authorizationStatusColor: Color {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return .green
        case .authorizedWhenInUse:
            return .orange
        default:
            return .red
        }
    }
    
}

struct SettingsView: View {
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        SettingsViewContent(locationService: locationService)
    }
}

#Preview {
    let container = try! ModelContainer(for: StayInterval.self, LocationEventLog.self)
    let ctx = ModelContext(container)
    let repo = StayRepository(modelContext: ctx)
    let engine = StayEngine(repository: repo)
    return SettingsView(
        locationService: LocationService(stayEngine: engine, repository: repo)
    )
}
