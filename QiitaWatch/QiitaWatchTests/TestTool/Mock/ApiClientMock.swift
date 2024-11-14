//
//  ApiClientMock.swift
//  QiitaWatchTests
//
//  Created by 佐藤汰一 on 2024/11/14.
//

import XCTest

@testable import QiitaWatch

struct ApiClientMock<ExpectedOutput>: ApiClient where ExpectedOutput: Decodable, ExpectedOutput: Sendable {
    
    private let expectedInput: ApiService
    private let expectedResult: Result<ExpectedOutput, Error>
    
    init(expectedInput: ApiService, expectedResult: Result<ExpectedOutput, Error>) {
        
        self.expectedInput = expectedInput
        self.expectedResult = expectedResult
    }
    
    func get<Output>(_ service: QiitaWatch.ApiService) async throws -> Output where Output : Decodable, Output : Sendable {
        
        XCTAssertEqual(service, expectedInput)
        return try expectedResult.get() as! Output
    }
}
