//
//  FetchingState.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/19/25.
//

public enum FetchingState<Value> {
    case idle
    case fetching
    case fetched(Value)
    case error(message: String)
}
