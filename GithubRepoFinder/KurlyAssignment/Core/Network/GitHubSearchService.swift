//
//  GitHubSearchService.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/18/25.
//

import Combine
import Foundation

protocol GitHubSearchServiceProtocol {
    func searchRepositories(keyword: String, page: Int) -> AnyPublisher<GitHubSearchResponse, NetworkError>
}

final class GitHubSearchService: GitHubSearchServiceProtocol {
    private let client: HTTPClientProtocol

    init(client: HTTPClientProtocol = HTTPClient()) {
        self.client = client
    }

    func searchRepositories(keyword: String, page: Int) -> AnyPublisher<GitHubSearchResponse, NetworkError> {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/search/repositories"
        components.queryItems = [
            URLQueryItem(name: "q", value: keyword),
            URLQueryItem(name: "page", value: String(page))
        ]

        guard let url = components.url else {
            return Fail(error: NetworkError.invalidResponse).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        return client.request(request)
    }
}
