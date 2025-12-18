//
//  NetworkError.swift
//  KurlyAssignment
//
//  Created by Cursor on 12/18/25.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case decoding(Error)
    case transport(URLError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .httpStatus(let code):
            return "요청에 실패했습니다. (HTTP \(code))"
        case .decoding:
            return "데이터 처리 중 오류가 발생했습니다."
        case .transport:
            return "네트워크 연결을 확인해주세요."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
