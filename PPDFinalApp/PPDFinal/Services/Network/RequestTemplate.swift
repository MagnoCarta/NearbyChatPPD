import Foundation

public protocol RequestTemplate {
    associatedtype Response

    var url: URL? { get }
    var method: HTTPMethod { get }
    var path: String { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem] { get }
    var data: Data? { get }

    func decode(_ data: Data) throws -> Response
}

public extension RequestTemplate {
    var headers: [String: String] { [:] }
    var queryItems: [URLQueryItem] { [] }
    var data: Data? { nil }
}

public extension RequestTemplate where Self: Encodable {
    var data: Data? { try? JSONEncoder().encode(self) }
}

public extension RequestTemplate where Response: Decodable {
    func decode(_ data: Data) throws -> Response {
        return try JSONDecoder().decode(Response.self, from: data)
    }
}

public extension RequestTemplate where Response == Void {
    func decode(_ data: Data) throws -> Response { return }
}

extension RequestTemplate where Response == Data {
    public func decode(_ data: Data) throws -> Response { return data }
}
