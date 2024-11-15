//
//  AlertCase.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/14.
//

import Foundation

enum AlertCase {
    
    typealias Handler = @Sendable () -> Void
    
    case noHitQiitaUser(firstHandler: Handler) // ユーザ取得が0件だった場合のアラート
    case networkError(firstHandler: Handler) // 通信エラーの場合のアラート
}

// MARK: - alert contents definition

extension AlertCase {
    
    var title: String {
        
        switch self {
            
        case .noHitQiitaUser:
            return "ユーザーが取得できませんでした。"
            
        case .networkError:
            return "通信に失敗しました。"
            + "\n"
            + "通信環境の良い場所で再度お試しください。"
        }
    }
    
    var firstButtonTitle: String {
        
        switch self {
            
        case .noHitQiitaUser, .networkError:
            return "閉じる"
        }
    }
    
    var secondButtonTitle: String? {
        
        switch self {
            
        case .noHitQiitaUser, .networkError:
            return nil
        }
    }
}

// MARK: - conform equatable

extension AlertCase: Equatable {
    
    static func == (lhs: AlertCase, rhs: AlertCase) -> Bool {
        
        return lhs.title == rhs.title
        && lhs.firstButtonTitle == rhs.firstButtonTitle
        && lhs.secondButtonTitle == rhs.secondButtonTitle
    }
}
