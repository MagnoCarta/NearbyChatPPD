//
//  NetworkService.swift
//  PPDFinal
//
//  Created by Gilberto Magno on 04/08/25.
//

import Foundation

public protocol NetworkServiceInterface {
    func request<Request: RequestTemplate>(
        _ request: Request,
        using session: URLSession,
        completion: @escaping (Result<Request.Response, NetworkServiceError>) -> Void)

    func request<Request: RequestTemplate>(
        _ request: Request,
        using session: URLSession) async -> (Result<Request.Response, NetworkServiceError>)
}

public class NetworkService: NetworkServiceInterface {
    static public let shared: NetworkService = NetworkService()

    public func request<Request: RequestTemplate>(
        _ request: Request,
        using session: URLSession = URLSession.shared,
        completion: @escaping (Result<Request.Response, NetworkServiceError>) -> Void) {
            guard let url = request.url else {
                return completion(.failure(NetworkServiceError.unknownError))
            }

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = request.method.rawValue
            urlRequest.httpBody = request.data
            urlRequest.allHTTPHeaderFields = request.headers

            session.dataTask(with: urlRequest) { data, response, error in
                DispatchQueue.main.async {
                    if error != nil {
                        return completion(.failure(NetworkServiceError.unknownError))
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        return completion(.failure(NetworkServiceError.unknownError))
                    }

                    switch httpResponse.statusCode {
                    case 401:
                        return completion(.failure(NetworkServiceError.unauthorized))
                    case 400...499:

                        return completion(.failure(NetworkServiceError.clientError))
                    case 500...599:
                        return completion(.failure(NetworkServiceError.serverError))
                    default:
                        break
                    }

                    guard let data = data else {
                        return completion(.failure(NetworkServiceError.unknownError))
                    }
                    do {
                        try completion(.success(request.decode(data)))
                    } catch {
                        completion(.failure(NetworkServiceError.unknownError))
                    }
                }
            }.resume()
        }

    @MainActor
    public func request<Request>(_ request: Request,
                                 using session: URLSession) async -> (
                            Result<Request.Response,
                            NetworkServiceError>
                          ) where Request: RequestTemplate {
        guard let url = request.url else {
            return .failure(NetworkServiceError.unknownError)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.data
        urlRequest.allHTTPHeaderFields = request.headers

        do {
            let result = try await session.data(for: urlRequest)
            let data = result.0
            let response = result.1

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NetworkServiceError.unknownError)
            }

            switch httpResponse.statusCode {
            case 401:
                return .failure(NetworkServiceError.unauthorized)
            case 400...499:
                return .failure(NetworkServiceError.clientError)
            case 500...599:
                return .failure(NetworkServiceError.serverError)
            default:
                break
            }

            return .success(try request.decode(data))

        } catch {
            print(error)
            return .failure(NetworkServiceError.unknownError)
        }

    }

}
