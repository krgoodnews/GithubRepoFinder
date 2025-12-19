//
//  RepositorySearchViewModel.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/18/25.
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
    @Published private(set) var isLoadingNextPage: Bool = false
    @Published private(set) var errorMessage: String?

    private let service: GitHubSearchServiceProtocol
    private var requestCancellable: AnyCancellable?

    private var currentKeyword: String = ""
    private var currentPage: Int = 0
    private var totalCount: Int = 0
    private var loadedPages = Set<Int>()
    private var nextPageThreshold: Int = 5

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
        isLoadingNextPage = false

        currentKeyword = ""
        currentPage = 0
        totalCount = 0
        loadedPages = []
        nextPageThreshold = 5
    }

    func loadNextPageIfNeeded(currentIndex: Int) {
        guard currentKeyword.isEmpty == false else { return }
        guard isLoading == false else { return }
        guard isLoadingNextPage == false else { return }
        guard repositories.isEmpty == false else { return }

        let triggerIndex = max(0, repositories.count - nextPageThreshold)
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
            nextPageThreshold = 5
        }

        errorMessage = nil
        if page == 1 {
            isLoading = true
        } else {
            isLoadingNextPage = true
        }

        requestCancellable = service.searchRepositories(keyword: keyword, page: page)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                if page == 1 {
                    self.isLoading = false
                } else {
                    self.isLoadingNextPage = false
                }

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
                
                if page == 1 {
                    self.nextPageThreshold = max(1, response.items.count / 2)
                }
                self.repositories.append(contentsOf: response.items)
            }
    }
}


