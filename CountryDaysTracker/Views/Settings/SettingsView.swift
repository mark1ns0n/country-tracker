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
    @Environment(\.openURL) private var openURL
    
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
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            openURL(url)
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
                        Text(appVersionText)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        guard let build, build != version else { return version }
        return "\(version) (\(build))"
    }
}

struct SettingsView: View {
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        SettingsViewContent(locationService: locationService)
    }
}

#Preview {
    let container = try! AppModelSchema.makeContainer(inMemory: true)
    let ctx = ModelContext(container)
    let repo = StayRepository(modelContext: ctx)
    let engine = StayEngine(repository: repo)
    return SettingsView(
        locationService: LocationService(stayEngine: engine, repository: repo)
    )
}
