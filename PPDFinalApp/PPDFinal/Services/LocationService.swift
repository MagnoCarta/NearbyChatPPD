import Foundation
import CoreLocation
import Observation

@Observable
final class LocationService: NSObject {
    private let manager = CLLocationManager()
    var authorizationStatus: CLAuthorizationStatus
    var lastLocation: CLLocation?
    /// Called whenever a new location is reported by the manager.
    var onLocationUpdate: ((CLLocation) -> Void)?

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        switch authorizationStatus {
        case .notDetermined:
            requestAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
#if os(iOS)
            if self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
#elseif os(macOS)
            if self.authorizationStatus == .authorized || self.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
#endif
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async {
            if let location = locations.last {
                self.lastLocation = location
                self.onLocationUpdate?(location)
                print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }
}
