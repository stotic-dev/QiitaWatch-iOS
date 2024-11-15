//
//  SearchWordRepository.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/14.
//

import Foundation
import SwiftData

@MainActor
final class SearchWordRepository {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        
        self.context = context
    }
    
    /// 保存している検索文字を全て取得する
    /// - Parameter order: 保存日時のソート順。デフォルトは降順
    func fetchAll(order: SortOrder = .reverse) throws -> [SearchWordModel] {
        
        let sortDescriptor = SortDescriptor<SearchWordModel>(\.createdAt, order: order)
        return try context.fetch(FetchDescriptor<SearchWordModel>(sortBy: [sortDescriptor]))
    }
    
    /// 検索文字を保存する
    /// - Parameter word: 保存する文字
    func insert(_ word: String) {
        
        let model = SearchWordModel(word: word)
        context.insert(model)
    }
    
    /// 保存している検索文字を削除する
    /// - Parameter id: モデルのID
    func delete(_ id: String) {
        
        let predicateById = #Predicate<SearchWordModel> { $0.id == id }
        guard let target = try? context.fetch(FetchDescriptor<SearchWordModel>(predicate: predicateById)).first else {
            
            return
        }
        context.delete(target)
    }
}
