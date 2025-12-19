//
//  SearchScreenViewModel.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/18/25.
//

import Combine
import Foundation

/// 검색 화면(최근 검색어) 전용 ViewModel
///
/// - 최근 검색어 관리(추가/삭제/전체삭제)
/// - 검색 트리거 이벤트 방출
final class SearchHomeViewModel {
    struct Output {
        let showSearchResults: AnyPublisher<String, Never>
    }

    private let showSearchResultsSubject = PassthroughSubject<String, Never>()
    private let recentKeywordStore: RecentKeywordStore

    init(recentKeywordStore: RecentKeywordStore = RecentKeywordStore()) {
        self.recentKeywordStore = recentKeywordStore
    }

    var output: Output {
        Output(showSearchResults: showSearchResultsSubject.eraseToAnyPublisher())
    }

    var recentKeywordsPublisher: AnyPublisher<[RecentKeyword], Never> {
        recentKeywordStore.$recentKeywords.eraseToAnyPublisher()
    }

    var recentKeywords: [RecentKeyword] {
        recentKeywordStore.recentKeywords
    }

    func recentKeywords(limit: Int) -> [RecentKeyword] {
        Array(recentKeywordStore.recentKeywords.prefix(max(0, limit)))
    }

    func autocompleteKeywords(for input: String) -> [RecentKeyword] {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return [] }

        let lowercasedInput = trimmed.lowercased()
        let items = recentKeywordStore.recentKeywords

        // 최근 검색어(내림차순)에서
        // 1) 전방 일치 우선
        // 2) 포함 일치 후순위
        // 로 결합하면, 구현은 단순하면서도 체감 품질이 좋습니다.
        let prefixMatches = items.filter { $0.keyword.lowercased().hasPrefix(lowercasedInput) }
        let containsMatches = items.filter {
            let keyword = $0.keyword.lowercased()
            return keyword.hasPrefix(lowercasedInput) == false && keyword.contains(lowercasedInput)
        }

        return prefixMatches + containsMatches
    }

    func submitSearch(keyword: String) {
        triggerSearch(keyword: keyword)
    }

    func selectRecentKeyword(keyword: String) {
        triggerSearch(keyword: keyword)
    }

    func deleteRecentKeyword(keyword: String) {
        recentKeywordStore.remove(keyword: keyword)
    }

    func deleteAllRecentKeywords() {
        recentKeywordStore.removeAll()
    }

    private func triggerSearch(keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        recentKeywordStore.add(keyword: trimmed)
        showSearchResultsSubject.send(trimmed)
    }
}
