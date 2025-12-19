//
//  RecentKeywordStore.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/18/25.
//

import Combine
import Foundation

final class RecentKeywordStore {
    @Published private(set) var recentKeywords: [RecentKeyword] = []

    private enum Const {
        static let maxCount = 10
        static let userDefaultsKey = "recent_keywords_v1"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func add(keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        // 동일 키워드는 최신으로 갱신
        recentKeywords.removeAll { $0.keyword.caseInsensitiveCompare(trimmed) == .orderedSame }
        recentKeywords.insert(RecentKeyword(keyword: trimmed, searchedAt: Date()), at: 0)

        if recentKeywords.count > Const.maxCount {
            recentKeywords = Array(recentKeywords.prefix(Const.maxCount))
        }

        save()
    }

    func remove(keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        recentKeywords.removeAll { $0.keyword.caseInsensitiveCompare(trimmed) == .orderedSame }
        save()
    }

    func removeAll() {
        recentKeywords = []
        userDefaults.removeObject(forKey: Const.userDefaultsKey)
    }

    private func load() {
        guard let data = userDefaults.data(forKey: Const.userDefaultsKey) else {
            recentKeywords = []
            return
        }

        do {
            let decoded = try JSONDecoder().decode([RecentKeyword].self, from: data)
            recentKeywords = Array(decoded.prefix(Const.maxCount))
        } catch {
            recentKeywords = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(recentKeywords)
            userDefaults.set(data, forKey: Const.userDefaultsKey)
        } catch {
            // 저장 실패는 UX에 치명적이지 않아 조용히 무시합니다.
        }
    }
}

struct RecentKeyword: Codable, Hashable {
    let keyword: String
    let searchedAt: Date
}
