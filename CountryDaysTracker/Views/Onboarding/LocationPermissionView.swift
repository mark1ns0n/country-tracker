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
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 24) {
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
                Text("We use your location to:")
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

            if locationService.authorizationStatus == .authorizedWhenInUse {
                Text("Background country tracking requires \"Always\" access. You can continue now, but updates will be limited to times when the app is open.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
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

                    Button(action: {
                        didCompleteOnboarding = true
                    }) {
                        Text("Continue with Limited Tracking")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary)
                            .cornerRadius(12)
                    }
                }

                if locationService.authorizationStatus == .authorizedAlways {
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

                if locationService.authorizationStatus == .denied ||
                    locationService.authorizationStatus == .restricted {
                    Button("Open System Settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        openURL(url)
                    }
                    .font(.headline)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 32)
        .padding(.bottom, 24)
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
    let container = try! AppModelSchema.makeContainer(inMemory: true)
    let ctx = ModelContext(container)
    let repo = StayRepository(modelContext: ctx)
    let engine = StayEngine(repository: repo)
    return LocationPermissionView(
        locationService: LocationService(stayEngine: engine, repository: repo),
        didCompleteOnboarding: .constant(false)
    )
}
