//
//  SearchWordModel.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/14.
//

import Foundation
import SwiftData

@Model
final class SearchWordModel {
    
    @Attribute(.unique) var id: String
    var word: String
    var createdAt: TimeInterval
    
    init(word: String) {
        
        self.id = UUID().uuidString
        self.word = word
        self.createdAt = Date.now.timeIntervalSince1970
    }
}