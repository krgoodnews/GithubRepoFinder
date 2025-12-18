//
//  SearchViewModel.swift
//  KurlyAssignment
//
//  Created by Cursor on 12/18/25.
//

import Combine
import Foundation

final class SearchViewModel {
    @Published private(set) var repositories: [GitHubRepository] = []
    @Published private(set) var totalCountText: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let service: GitHubSearchServiceProtocol
    private var requestCancellable: AnyCancellable?

    init(service: GitHubSearchServiceProtocol = GitHubSearchService()) {
        self.service = service
    }

    func submitSearch(keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        search(keyword: trimmed, page: 1)
    }

    func clearResults() {
        requestCancellable?.cancel()
        requestCancellable = nil

        repositories = []
        totalCountText = ""
        errorMessage = nil
        isLoading = false
    }

    private func search(keyword: String, page: Int) {
        requestCancellable?.cancel()
        errorMessage = nil
        isLoading = true

        requestCancellable = service.searchRepositories(keyword: keyword, page: page)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false

                if case let .failure(error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                guard let self else { return }
                self.repositories = response.items
                self.totalCountText = "총 \(response.totalCount)개"
            }
    }
}


