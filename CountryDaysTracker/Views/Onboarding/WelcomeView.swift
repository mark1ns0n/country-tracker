//
//  WelcomeView.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var showOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "globe.europe.africa.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.blue)
            
            // Title
            Text("Country Days Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Description
            Text("Track how many days you spend in each country. View your travel history on calendar and map.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Continue button
            Button(action: {
                showOnboarding = false
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }
}

#Preview {
    WelcomeView(showOnboarding: .constant(true))
}
