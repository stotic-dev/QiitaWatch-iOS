//
//  QiitaUserModel.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/14.
//

struct QiitaUserModel: Decodable, Equatable {
    
    /// ユーザーID
    let id: String
    /// 名前
    let name: String
    /// 説明文
    let description: String
    /// フォロー数
    let followees_count: Int
    /// フォロワー数
    let followers_count: Int
    /// プロフィール画像
    let profile_image_url: String
}
