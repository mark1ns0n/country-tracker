//
//  LocationService.swift
//  CountryDaysTracker
//
//  Created on 14 December 2025.
//

import Foundation
import CoreLocation
import SwiftData

@MainActor
class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var stayEngine: StayEngine
    private var repository: StayRepository
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isMonitoring = false
        // Placeholder support for deferred wiring of shared modelContext
        static let placeholder: LocationService = {
            let dummyContainer = try! ModelContainer(for: StayInterval.self, LocationEventLog.self)
            let dummyRepo = StayRepository(modelContext: ModelContext(dummyContainer))
            let dummy = LocationService(stayEngine: StayEngine(repository: dummyRepo), repository: dummyRepo)
            dummy.isPlaceholder = true
            return dummy
        }()
        private(set) var isPlaceholder: Bool = false
        func adopt(from other: LocationService) {
            // copy essential state from a real instance
            self.isPlaceholder = false
            self.authorizationStatus = other.authorizationStatus
            self.isMonitoring = other.isMonitoring
            self.stayEngine = other.stayEngine
            self.repository = other.repository
            self.locationManager.delegate = self
        }
    
    init(stayEngine: StayEngine, repository: StayRepository) {
        self.stayEngine = stayEngine
        self.repository = repository
        super.init()
        self.locationManager.delegate = self
        self.authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    /// Request location permissions (step by step: WhenInUse → Always)
    func requestPermissions() {
        switch authorizationStatus {
        case .notDetermined:
            print("🔐 Requesting WhenInUse authorization")
            // First request "When In Use"
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            print("🔐 Upgrading to Always authorization")
            // Then request "Always"
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("✅ Already have Always authorization")
        default:
            print("⚠️ Location permissions denied or restricted")
        }
    }
    
    /// Start monitoring location changes
    func start() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            print("⚠️ Cannot start monitoring without location permissions")
            return
        }
        
        print("🌍 Starting monitoring (auth=\(authorizationStatus.rawValue))")
        // Start significant location changes
        locationManager.startMonitoringSignificantLocationChanges()
        
        // Start monitoring visits
        locationManager.startMonitoringVisits()
        
        isMonitoring = true
        print("🌍 Started location monitoring")
    }
    
    /// Stop monitoring location changes
    func stop() {
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopMonitoringVisits()
        isMonitoring = false
        print("🛑 Stopped location monitoring")
    }
    
    /// Request a single location update (for sync on app open)
    func requestLocation() {
        print("📡 requestLocation() invoked")
        locationManager.requestLocation()
    }
    
    // MARK: - Private Methods
    
    /// Reverse geocode location to get country code
    private func processLocation(_ location: CLLocation, source: String) {
        print("📍 Processing location: \(location.coordinate.latitude), \(location.coordinate.longitude) acc=\(location.horizontalAccuracy) from \(source)")
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Geocoding error: \(error.localizedDescription)")
                    self.repository.appendLog(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        source: source,
                        accepted: false,
                        note: "Geocoding error: \(error.localizedDescription)"
                    )
                    return
                }
                guard let placemark = placemarks?.first,
                      let countryCodeRaw = placemark.isoCountryCode,
                      !countryCodeRaw.isEmpty else {
                    print("⚠️ No country code found")
                    self.repository.appendLog(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        source: source,
                        accepted: false,
                        note: "No country code found"
                    )
                    return
                }
                let countryCode = countryCodeRaw.uppercased()
                print("🏴 Country code: \(countryCode)")

                self.repository.appendLog(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    source: source,
                    countryCodeCandidate: countryCode,
                    accepted: true
                )

                await self.stayEngine.processCountryUpdate(
                    countryCode: countryCode,
                    at: location.timestamp,
                    source: source,
                    confidence: location.horizontalAccuracy > 0 ? 1.0 / location.horizontalAccuracy : 0.0
                )
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            print("🔐 Authorization status changed: \(manager.authorizationStatus.rawValue)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            print("📬 didUpdateLocations count=\(locations.count) lastTs=\(location.timestamp)")
            self.processLocation(location, source: "significant-location")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        Task { @MainActor in
            let location = CLLocation(
                latitude: visit.coordinate.latitude,
                longitude: visit.coordinate.longitude
            )
            print("🏨 didVisit arrival=\(visit.arrivalDate) departure=\(visit.departureDate)")
            self.processLocation(location, source: "visit")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ Location manager error: \(error.localizedDescription)")
        }
    }
}
