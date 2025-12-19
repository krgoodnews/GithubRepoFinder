//
//  RepositorySearchViewModel.swift
//  KurlyAssignment
//
//  Created by Cursor on 12/18/25.
//

import Combine
import Foundation

/// GitHub Repository 검색 결과 화면 전용 ViewModel
///
/// - keyword/page 상태 관리
/// - 결과 누적(append) 및 초기 로드(reset) 구분
/// - 중복 요청 방지(동일 keyword에 대한 동일 page 재요청 방지)
final class RepositorySearchViewModel {
    @Published private(set) var repositories: [GitHubRepository] = []
    @Published private(set) var totalCountText: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let service: GitHubSearchServiceProtocol
    private var requestCancellable: AnyCancellable?

    private var currentKeyword: String = ""
    private var currentPage: Int = 0
    private var totalCount: Int = 0
    private var loadedPages = Set<Int>()

    init(service: GitHubSearchServiceProtocol = GitHubSearchService()) {
        self.service = service
    }

    func setKeyword(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            clearResults()
            return
        }

        if trimmed == currentKeyword {
            return
        }

        currentKeyword = trimmed
        search(keyword: trimmed, page: 1)
    }

    func clearResults() {
        requestCancellable?.cancel()
        requestCancellable = nil

        repositories = []
        totalCountText = ""
        errorMessage = nil
        isLoading = false

        currentKeyword = ""
        currentPage = 0
        totalCount = 0
        loadedPages = []
    }

    func loadNextPageIfNeeded(currentIndex: Int, threshold: Int = 5) {
        guard currentKeyword.isEmpty == false else { return }
        guard isLoading == false else { return }
        guard repositories.isEmpty == false else { return }

        let triggerIndex = max(0, repositories.count - threshold)
        guard currentIndex >= triggerIndex else { return }

        let nextPage = currentPage + 1
        guard canLoad(page: nextPage) else { return }
        search(keyword: currentKeyword, page: nextPage)
    }

    func retry() {
        guard currentKeyword.isEmpty == false else { return }
        let pageToRetry = max(1, currentPage)
        search(keyword: currentKeyword, page: pageToRetry)
    }

    private func canLoad(page: Int) -> Bool {
        guard page >= 1 else { return false }
        guard loadedPages.contains(page) == false else { return false }

        if totalCount > 0 {
            return repositories.count < totalCount
        }

        return true
    }

    private func search(keyword: String, page: Int) {
        guard canLoad(page: page) else { return }

        if page == 1 {
            requestCancellable?.cancel()
            repositories = []
            totalCountText = ""
            totalCount = 0
            loadedPages = []
            currentPage = 0
        }

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
                self.totalCount = response.totalCount
                self.totalCountText = "총 \(response.totalCount)개"

                self.currentKeyword = keyword
                self.currentPage = page
                self.loadedPages.insert(page)
                self.repositories.append(contentsOf: response.items)
            }
    }
}


