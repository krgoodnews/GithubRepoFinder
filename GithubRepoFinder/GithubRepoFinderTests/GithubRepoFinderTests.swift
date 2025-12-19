//
//  GithubRepoFinderTests.swift
//  GithubRepoFinderTests
//
//  Created by Goodnews on 12/18/25.
//

import Combine
import XCTest

@testable import GithubRepoFinder

final class GithubRepoFinderTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        cancellables = []
    }

    override func tearDownWithError() throws {
        cancellables = []
    }

    // MARK: - SearchHomeViewModel

    /// `submitSearch`가 입력을 trim한 뒤, 최근 검색어에 저장하고, 검색 이벤트를 방출하는지 검증합니다.
    func test_SearchHome_검색어_이벤트() {
        let suiteName = "SearchHomeViewModelTests_submitSearch"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = RecentKeywordStore(userDefaults: defaults)
        let viewModel = SearchHomeViewModel(recentKeywordStore: store)

        let exp = expectation(description: "search keyword emitted")
        var received: String?

        viewModel.output.showSearchResults
            .sink { keyword in
                received = keyword
                exp.fulfill()
            }
            .store(in: &cancellables)

        viewModel.submitSearch(keyword: "  swift  ")

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(received, "swift")
        XCTAssertEqual(viewModel.recentKeywords.first?.keyword, "swift")
    }

    /// `autocompleteKeywords`가 최근 검색어에서 전방일치(prefix)를 우선하고, 그 다음 포함일치(contains)를 뒤에 붙이는지 검증합니다.
    func test_SearchHome_자동완성_정렬() {
        let suiteName = "SearchHomeViewModelTests_autocomplete"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = RecentKeywordStore(userDefaults: defaults)
        store.add(keyword: "swift")
        store.add(keyword: "rxswift")
        store.add(keyword: "SwiftUI")

        let viewModel = SearchHomeViewModel(recentKeywordStore: store)
        let results = viewModel.autocompleteKeywords(for: "sw")

        XCTAssertEqual(results.map(\.keyword), ["SwiftUI", "swift", "rxswift"])
    }

    // MARK: - RepositorySearchViewModel

    /// `setKeyword`가 1페이지를 로드하고, `repositories`/`totalCountText`를 기대 값으로 업데이트하는지 검증합니다.
    func test_검색결과_키워드_초기로드() {
        let response = GitHubSearchResponse(
            totalCount: 1234,
            items: [
                Self.repo(id: 1, name: "swift", owner: "apple"),
                Self.repo(id: 2, name: "swift-nio", owner: "apple")
            ]
        )
        let service = MockGitHubSearchService(responses: [1: .success(response)])
        let viewModel = RepositorySearchViewModel(service: service)

        let exp = expectation(description: "repositories updated")
        viewModel.$repositories
            .dropFirst()
            .sink { repos in
                if repos.count == 2 {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.setKeyword("swift")

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(service.calls, [.init(keyword: "swift", page: 1)])
        XCTAssertEqual(viewModel.totalCountText, "1,234개 저장소")
        XCTAssertEqual(viewModel.repositories.count, 2)
    }

    /// `loadNextPageIfNeeded`가 임계 인덱스에서 다음 페이지를 1회만 요청하고, 결과를 append하는지 검증합니다.
    func test_검색결과_다음페이지_추가() {
        let page1 = GitHubSearchResponse(
            totalCount: 6,
            items: [
                Self.repo(id: 1, name: "swift", owner: "apple"),
                Self.repo(id: 2, name: "swift-nio", owner: "apple"),
                Self.repo(id: 3, name: "swift-format", owner: "apple"),
                Self.repo(id: 4, name: "swift-collections", owner: "apple")
            ]
        )
        let page2 = GitHubSearchResponse(
            totalCount: 6,
            items: [
                Self.repo(id: 5, name: "rxswift", owner: "ReactiveX"),
                Self.repo(id: 6, name: "CombineExt", owner: "CombineCommunity")
            ]
        )

        let service = MockGitHubSearchService(
            responses: [
                1: .success(page1),
                2: .success(page2)
            ]
        )
        let viewModel = RepositorySearchViewModel(service: service)

        let page1Loaded = expectation(description: "page1 loaded")
        let page2Loaded = expectation(description: "page2 loaded")

        viewModel.$repositories
            .dropFirst()
            .sink { repos in
                if repos.count == 4 { page1Loaded.fulfill() }
                if repos.count == 6 { page2Loaded.fulfill() }
            }
            .store(in: &cancellables)

        viewModel.setKeyword("swift")
        wait(for: [page1Loaded], timeout: 1.0)

        viewModel.loadNextPageIfNeeded(currentIndex: 2)
        wait(for: [page2Loaded], timeout: 1.0)

        viewModel.loadNextPageIfNeeded(currentIndex: 5)

        XCTAssertEqual(
            service.calls,
            [
                .init(keyword: "swift", page: 1),
                .init(keyword: "swift", page: 2)
            ]
        )
        XCTAssertEqual(viewModel.repositories.count, 6)
    }

    // MARK: - Helpers

    private static func repo(id: Int, name: String, owner: String) -> GitHubRepository {
        GitHubRepository(
            id: id,
            name: name,
            fullName: "\(owner)/\(name)",
            htmlURL: URL(string: "https://github.com/\(owner)/\(name)")!,
            owner: .init(
                login: owner,
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/\(id)")!
            )
        )
    }
}

private final class MockGitHubSearchService: GitHubSearchServiceProtocol {
    struct Call: Equatable {
        let keyword: String
        let page: Int
    }

    enum Stub {
        case success(GitHubSearchResponse)
        case failure(NetworkError)
    }

    private let responses: [Int: Stub]
    private(set) var calls: [Call] = []

    init(responses: [Int: Stub]) {
        self.responses = responses
    }

    func searchRepositories(keyword: String, page: Int) -> AnyPublisher<GitHubSearchResponse, NetworkError> {
        calls.append(.init(keyword: keyword, page: page))

        switch responses[page] {
        case .success(let response):
            return Just(response)
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        case .none:
            return Fail(error: NetworkError.invalidResponse).eraseToAnyPublisher()
        }
    }
}
