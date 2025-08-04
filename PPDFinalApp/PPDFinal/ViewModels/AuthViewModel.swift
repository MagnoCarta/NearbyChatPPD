import Foundation
import CoreLocation

@Observable
final class AuthViewModel {
    private let locationService: LocationService
    private let apiClient: APIClient

    var currentUser: User?
    var username: String = ""
    var errorMessage: String?

    @MainActor
    init(locationService: LocationService = LocationService(), apiClient: APIClient? = nil) {
        self.locationService = locationService
        // Using 127.0.0.1 ensures the client connects over IPv4 which matches
        // the default Vapor server configuration used during development.
        self.apiClient = apiClient ?? APIClient(baseURL: URL(string: "http://127.0.0.1:8080")!)
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    func register() {
        guard !username.isEmpty else {
            errorMessage = "Username required"
            print("Registration failed: username required")
            return
        }
        let coordinate = locationService.lastLocation?.coordinate
        let location = Location(latitude: coordinate?.latitude ?? 0,
                                longitude: coordinate?.longitude ?? 0)
        Task { @APIActor in
            do {
                let user = try await apiClient.register(username: username, location: location)
                await MainActor.run {
                    if let user = user {
                        currentUser = user
                        errorMessage = nil
                    } else {
                        errorMessage = "User already exists"
                    }
                }
            } catch {
                await MainActor.run { errorMessage = "Registration failed" }
            }
        }
    }

    func login() {
        guard !username.isEmpty else {
            errorMessage = "Username required"
            print("Login failed: username required")
            return
        }
        let coordinate = locationService.lastLocation?.coordinate
        let location = Location(latitude: coordinate?.latitude ?? 0,
                                longitude: coordinate?.longitude ?? 0)
        Task { @APIActor in
            do {
                let user = try await apiClient.login(username: username, location: location)
                if let user = user {
                    await MainActor.run {
                        currentUser = user
                        errorMessage = nil
                    }
                    try? await apiClient.updateStatus(for: user.id, status: .online)
                } else {
                    await MainActor.run { errorMessage = "User does not exist" }
                }
            } catch {
                await MainActor.run { errorMessage = "Login failed" }
            }
        }
    }

    func logout() {
        if let user = currentUser {
            Task { @APIActor in
                try? await apiClient.updateStatus(for: user.id, status: .offline)
            }
        }
        print("User \(currentUser?.username ?? "") logged out")
        currentUser = nil
        username = ""
    }
}
