import Foundation

@globalActor
actor APIActor {
    static let shared = APIActor()
}

@APIActor
final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @MainActor
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    struct ContactSyncBody: Codable {
        let userID: UUID
        let location: Location
        let radius: Double
        let name: String?
    }

    private struct UserResponse: Codable {
        let id: UUID
        let name: String
        let location: Location
        let status: UserStatus
    }

    func register(username: String, location: Location) async throws -> User? {
        let url = baseURL.appending(path: "users").appending(path: "register").appending(path: username)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(location)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        let dto = try decoder.decode(UserResponse.self, from: data)
        return User(id: dto.id, username: dto.name, location: dto.location, status: dto.status)
    }

    func login(username: String, location: Location) async throws -> User? {
        let url = baseURL.appending(path: "users").appending(path: "login").appending(path: username)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(location)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        let dto = try decoder.decode(UserResponse.self, from: data)
        return User(id: dto.id, username: dto.name, location: dto.location, status: dto.status)
    }

    func fetchQueuedMessages(for userID: UUID) async throws -> [Message] {
        let url = baseURL.appending(path: "queue").appending(path: userID.uuidString)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        print("Fetching queued messages for \(userID)")
        let (data, _) = try await session.data(for: request)
        return try decoder.decode([Message].self, from: data)
    }

    func fetchMessageHistory(between user1: UUID, and user2: UUID) async throws -> [Message] {
        let url = baseURL.appending(path: "messages")
            .appending(path: user1.uuidString)
            .appending(path: user2.uuidString)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        print("Fetching message history between \(user1) and \(user2)")
        let (data, _) = try await session.data(for: request)
        return try decoder.decode([Message].self, from: data)
    }

    func updateStatus(for userID: UUID, status: UserStatus) async throws {
        let url = baseURL.appending(path: "status").appending(path: userID.uuidString)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(status)
        print("Updating status for \(userID) to \(status.rawValue)")
        _ = try await session.data(for: request)
    }

    func syncContacts(for userID: UUID, name: String? = nil, location: Location, radius: Double) async throws -> [Contact] {
        let url = baseURL.appending(path: "contacts").appending(path: "sync")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ContactSyncBody(userID: userID, location: location, radius: radius, name: name)
        request.httpBody = try encoder.encode(body)
        print("Syncing contacts for \(userID)")
        let (data, _) = try await session.data(for: request)
        return try decoder.decode([Contact].self, from: data)
    }
}
