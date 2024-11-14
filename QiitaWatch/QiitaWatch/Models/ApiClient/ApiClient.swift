//
//  ApiClient.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/14.
//

import Alamofire
import Foundation

protocol ApiClient {
    
    /// GETリクエストを送信する
    /// - Parameter service: リクエスト内容の構造体
    /// - Returns: GETリクエストで期待するレスポンスボディ
    func get<Output>(_ service: ApiService) async throws -> Output where Output: Decodable, Output: Sendable
}

struct QiitaApiClientImpl: ApiClient {
    
    private let timeout: TimeInterval = 5
    
    func get<Output>(_ service: ApiService) async throws -> Output where Output : Decodable, Output: Sendable {
        
        try await withCheckedThrowingContinuation { continuation in
            
            AF.request(service.url, method: .get,
                       headers: getCommonHeader(),
                       requestModifier: {
                $0.timeoutInterval = timeout
                $0.cachePolicy = .reloadRevalidatingCacheData
            })
            .responseDecodable(of: Output.self) { response in
                
                switch response.result {
                    
                case .success(let data):
                    continuation.resume(returning: data)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            .resume()
        }
    }
}

private extension QiitaApiClientImpl {
    
    func getCommonHeader() -> HTTPHeaders {
        
        let authHeader = HTTPHeader(name: "Authorization",
                                    value: "Bearer \(InfoPlistReader.getString(key: .qiitaAuthToken))")
        return HTTPHeaders([authHeader])
    }
}
