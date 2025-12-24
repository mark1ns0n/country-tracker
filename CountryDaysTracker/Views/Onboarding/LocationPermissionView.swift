//
//  LocationPermissionView.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI
import SwiftData

struct LocationPermissionView: View {
    @ObservedObject var locationService: LocationService
    @Binding var didCompleteOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: "location.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue)
            
            // Title
            Text("Location Permission")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Description
            VStack(spacing: 15) {
                Text("We need access to your location to:")
                    .font(.headline)
                
                PermissionReasonRow(
                    icon: "flag.fill",
                    text: "Detect which country you're in"
                )
                
                PermissionReasonRow(
                    icon: "calendar",
                    text: "Track days spent per country"
                )
                
                PermissionReasonRow(
                    icon: "map.fill",
                    text: "Show your travel history"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 15) {
                if locationService.authorizationStatus == .notDetermined {
                    Button(action: {
                        locationService.requestPermissions()
                    }) {
                        Text("Allow While Using")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                
                if locationService.authorizationStatus == .authorizedWhenInUse {
                    Button(action: {
                        locationService.requestPermissions()
                    }) {
                        Text("Allow Always (Recommended)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                
                if locationService.authorizationStatus == .authorizedAlways ||
                   locationService.authorizationStatus == .authorizedWhenInUse {
                    Button(action: {
                        didCompleteOnboarding = true
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

struct PermissionReasonRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    // Build a shared in-memory SwiftData context for preview
    let container = try! ModelContainer(for: StayInterval.self, LocationEventLog.self)
    let ctx = ModelContext(container)
    let repo = StayRepository(modelContext: ctx)
    let engine = StayEngine(repository: repo)
    return LocationPermissionView(
        locationService: LocationService(stayEngine: engine, repository: repo),
        didCompleteOnboarding: .constant(false)
    )
}
