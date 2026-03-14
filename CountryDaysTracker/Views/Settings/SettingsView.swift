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
    @Environment(\.openURL) private var openURL
    @State private var homeCountryCode = ""
    @State private var activeRuleIdentifier = ""
    @State private var availableRules: [ResidencyRuleOption] = []
    @State private var residencyEvaluation: ResidencyEvaluation?
    @State private var residencyError: String?
    @State private var isResidencyLoaded = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Residency") {
                    if isResidencyLoaded {
                        TextField("Home Country Code", text: $homeCountryCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()

                        Button("Save Home Country") {
                            saveHomeCountry()
                        }
                        .disabled(homeCountryCode.trimmingCharacters(in: .whitespacesAndNewlines).count != 2)

                        Picker("Active Rule", selection: $activeRuleIdentifier) {
                            ForEach(availableRules) { rule in
                                Text(rule.title).tag(rule.id)
                            }
                        }
                        .onChange(of: activeRuleIdentifier) { _, newIdentifier in
                            guard isResidencyLoaded, !newIdentifier.isEmpty else { return }
                            activateRule(newIdentifier)
                        }

                        if let selectedRule = availableRules.first(where: { $0.id == activeRuleIdentifier }) {
                            Text(selectedRule.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        if let residencyEvaluation {
                            ResidencySummaryContent(
                                evaluation: residencyEvaluation,
                                accentCountryCode: homeCountryCode
                            )
                        }

                        NavigationLink("Manual Corrections") {
                            PresenceDayOverridesView()
                        }
                    } else {
                        ProgressView("Loading residency settings...")
                    }

                    if let residencyError {
                        Text(residencyError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

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
            .onAppear { loadResidencySettings() }
            .onReceive(NotificationCenter.default.publisher(for: .presenceDaysDidChange)) { _ in
                loadResidencySettings()
            }
            .onReceive(NotificationCenter.default.publisher(for: .residencySettingsDidChange)) { _ in
                loadResidencySettings()
            }
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

    private func loadResidencySettings() {
        let repository = ResidencySettingsRepository(modelContext: modelContext)
        let snapshotService = ResidencySnapshotService(modelContext: modelContext)

        do {
            let profile = try repository.ensureDefaults()
            let rules = try repository.fetchRuleOptions()
            let evaluation = try snapshotService.currentEvaluation()
            homeCountryCode = profile.homeCountryCode
            activeRuleIdentifier = profile.activeRuleIdentifier ?? ResidencySettingsRepository.defaultRuleIdentifier
            availableRules = rules
            residencyEvaluation = evaluation
            residencyError = nil
            isResidencyLoaded = true
        } catch {
            residencyError = "Failed to load residency settings"
            residencyEvaluation = nil
            isResidencyLoaded = true
        }
    }

    private func saveHomeCountry() {
        let repository = ResidencySettingsRepository(modelContext: modelContext)

        do {
            try repository.updateHomeCountryCode(homeCountryCode)
            ResidencyWidgetSyncService(modelContext: modelContext).sync()
            NotificationCenter.default.post(name: .residencySettingsDidChange, object: nil)
            loadResidencySettings()
        } catch {
            residencyError = "Failed to save home country"
        }
    }

    private func activateRule(_ identifier: String) {
        let repository = ResidencySettingsRepository(modelContext: modelContext)

        do {
            try repository.activateRule(identifier: identifier)
            ResidencyWidgetSyncService(modelContext: modelContext).sync()
            NotificationCenter.default.post(name: .residencySettingsDidChange, object: nil)
            loadResidencySettings()
        } catch {
            residencyError = "Failed to activate rule"
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
    let container = try! AppModelSchema.makeContainer(inMemory: true)
    let ctx = ModelContext(container)
    _ = try? ResidencySettingsRepository(modelContext: ctx).ensureDefaults()
    ctx.insert(PresenceDay(date: DateUtils.startOfDay(Date()), countryCode: "RU", source: "preview"))
    _ = try? ctx.save()
    let repo = StayRepository(modelContext: ctx)
    let engine = StayEngine(repository: repo)
    return SettingsView(
        locationService: LocationService(stayEngine: engine, repository: repo)
    )
    .modelContainer(container)
}
