//
//  QiitaUserRepository.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/14.
//

import Foundation

struct QiitaUserRepository {
    
    private let client: ApiClient
    
    init(client: ApiClient) {
        
        self.client = client
    }
    
    func fetchByUserId(_ userId: String) async throws -> QiitaUserModel {
        
        guard let service = ApiService.fetchQiitaUsersService(keyword: userId) else {
            
            throw FetchError.invalidUrlError
        }
        
        do {
            
            return try await client.get(service)
        }
        catch {
            
            throw FetchError.networkError(error)
        }
    }
}

// MARK: - error definition

extension QiitaUserRepository {
    
    enum FetchError: Error {
        
        /// ネットワークのエラー
        case networkError(Error)
        /// URLの生成に失敗した際のエラー
        case invalidUrlError
    }
}

// MARK: - service definition

extension ApiService {
    
    static func fetchQiitaUsersService(keyword: String) -> Self? {
        
        guard let url = URL(string: "https://qiita.com/api/v2/users/")?.appending(path: keyword) else {
            
            return nil
        }
        
        return ApiService(url: url)
    }
}
