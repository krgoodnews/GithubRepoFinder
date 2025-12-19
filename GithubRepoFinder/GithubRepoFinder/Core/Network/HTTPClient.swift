//
//  HTTPClient.swift
//  GithubRepoFinder
//
//  Created by Goodnews on 12/18/25.
//

import Combine
import Foundation

protocol HTTPClientProtocol {
    func request<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, NetworkError>
}

final class HTTPClient: HTTPClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, NetworkError> {
        session.dataTaskPublisher(for: request)
            .mapError { NetworkError.transport($0) }
            .tryMap { data, response -> Data in
                guard let http = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                guard (200..<300).contains(http.statusCode) else {
                    throw NetworkError.httpStatus(http.statusCode)
                }

                return data
            }
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                }

                return NetworkError.unknown(error)
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                }

                return NetworkError.decoding(error)
            }
            .eraseToAnyPublisher()
    }
}
