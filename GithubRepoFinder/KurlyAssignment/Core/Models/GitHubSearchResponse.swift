//
//  GitHubSearchResponse.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/18/25.
//

import Foundation

struct GitHubSearchResponse: Decodable {
    let totalCount: Int
    let items: [GitHubRepository]

    private enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}

struct GitHubRepository: Decodable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let htmlURL: URL
    let owner: Owner

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case htmlURL = "html_url"
        case owner
    }

    struct Owner: Decodable, Hashable {
        let login: String
        let avatarURL: URL

        private enum CodingKeys: String, CodingKey {
            case login
            case avatarURL = "avatar_url"
        }
    }
}
