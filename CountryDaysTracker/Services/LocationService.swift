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
    private var activeGeocoders: [UUID: CLGeocoder] = [:]
    private var stayEngine: StayEngine
    private var repository: StayRepository
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isMonitoring = false
    
    // Placeholder support for deferred wiring of shared modelContext
    static let placeholder: LocationService = {
        let dummyRepo = LocationService.makePlaceholderRepository()
        let dummy = LocationService(stayEngine: StayEngine(repository: dummyRepo), repository: dummyRepo)
        dummy.isPlaceholder = true
        return dummy
    }()

    private(set) var isPlaceholder: Bool = false

    func adopt(from other: LocationService) {
        // Copy essential state from a real instance.
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

    private static func makePlaceholderRepository() -> StayRepository {
        do {
            let container = try AppModelSchema.makeContainer(inMemory: true)
            return StayRepository(modelContext: ModelContext(container))
        } catch {
            fatalError("Critical: Could not create placeholder ModelContainer: \(error)")
        }
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
        guard authorizationStatus == .authorizedAlways else {
            print("⚠️ Background monitoring requires Always authorization")
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
    
    /// Reverse geocode location to get country code with retry mechanism
    private func processLocation(_ location: CLLocation, source: String, timestamp: Date? = nil, retryCount: Int = 0) {
        print("📍 Processing location: \(location.coordinate.latitude), \(location.coordinate.longitude) acc=\(location.horizontalAccuracy) from \(source)")
        let eventTimestamp = timestamp ?? location.timestamp
        let requestID = UUID()
        let geocoder = CLGeocoder()
        activeGeocoders[requestID] = geocoder

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                defer { self.activeGeocoders.removeValue(forKey: requestID) }
                if let error = error {
                    print("❌ Geocoding error: \(error.localizedDescription)")
                    
                    // Retry logic for network errors (max 3 attempts)
                    let nsError = error as NSError
                    let shouldRetry = (nsError.domain == kCLErrorDomain && 
                                      nsError.code == CLError.network.rawValue) ||
                                     nsError.code == CLError.geocodeFoundNoResult.rawValue
                    
                    if shouldRetry && retryCount < 3 {
                        let delay = pow(2.0, Double(retryCount)) // Exponential backoff: 1s, 2s, 4s
                        print("🔄 Retrying geocoding in \(delay)s (attempt \(retryCount + 1)/3)")
                        
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            self.processLocation(location, source: source, timestamp: eventTimestamp, retryCount: retryCount + 1)
                        }
                        return
                    }
                    
                    self.repository.appendLog(
                        timestamp: eventTimestamp,
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        source: source,
                        accepted: false,
                        note: "Geocoding error after \(retryCount) retries: \(error.localizedDescription)"
                    )
                    return
                }
                guard let placemark = placemarks?.first,
                      let countryCodeRaw = placemark.isoCountryCode,
                      !countryCodeRaw.isEmpty else {
                    print("⚠️ No country code found")
                    self.repository.appendLog(
                        timestamp: eventTimestamp,
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
                    timestamp: eventTimestamp,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    source: source,
                    countryCodeCandidate: countryCode,
                    accepted: true
                )

                await self.stayEngine.processCountryUpdate(
                    countryCode: countryCode,
                    at: eventTimestamp,
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
            let timestamp: Date
            if visit.arrivalDate != .distantPast {
                timestamp = visit.arrivalDate
            } else if visit.departureDate != .distantFuture {
                timestamp = visit.departureDate
            } else {
                timestamp = Date()
            }

            let location = CLLocation(
                coordinate: visit.coordinate,
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: -1,
                timestamp: timestamp
            )
            print("🏨 didVisit arrival=\(visit.arrivalDate) departure=\(visit.departureDate)")
            self.processLocation(location, source: "visit", timestamp: timestamp)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ Location manager error: \(error.localizedDescription)")
        }
    }
}
