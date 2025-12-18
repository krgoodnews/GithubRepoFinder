//
//  SearchScreenViewModel.swift
//  KurlyAssignment
//
//  Created by Cursor on 12/18/25.
//

import Combine
import Foundation

final class SearchScreenViewModel {
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
