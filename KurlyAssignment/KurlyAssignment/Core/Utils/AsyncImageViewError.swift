//
//  AsyncImageViewError.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/19/25.
//

import Foundation

public enum AsyncImageViewError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case invalidImageData

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "유효하지 않은 응답입니다."
        case .httpStatus(let code):
            return "이미지 요청에 실패했습니다. (HTTP \(code))"
        case .invalidImageData:
            return "이미지 데이터를 해석할 수 없습니다."
        }
    }
}
