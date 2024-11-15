//
//  QiitaUserRepository.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/14.
//

import Alamofire
import Foundation

struct QiitaUserRepository: Sendable {
    
    private let client: ApiClient
    
    init(client: ApiClient) {
        
        self.client = client
    }
    
    func fetchByUserId(_ userId: String) async throws(FetchError) -> QiitaUserModel {
                
        do {
            
            return try await client.get(.fetchQiitaUsersService(keyword: userId))
        }
        catch(let error as AFError) {
            
            if error.isResponseSerializationError {
                
                throw FetchError.noHitUser
            }
            
            throw FetchError.networkError(error)
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
        /// ユーザーがヒットしなかった
        case noHitUser
    }
}

// MARK: - service definition

extension ApiService {
    
    static func fetchQiitaUsersService(keyword: String) -> Self {
        
        guard let url = URL(string: "https://qiita.com/api/v2/users/")?.appending(path: keyword) else {
            
            // URLが生成できないケースは、固定値のURL自体に誤りがあるケースで外部の入力に依存せず定数の誤りなのでfatalエラーに倒す
            fatalError("Invalid URL.")
        }
        
        return ApiService(url: url)
    }
}
