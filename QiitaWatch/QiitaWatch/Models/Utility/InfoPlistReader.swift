//
//  InfoPlistReader.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/14.
//

import Foundation

struct InfoPlistReader {
    
    static func getString(key: PlistKey) -> String {
        
        return Bundle.main.object(forInfoDictionaryKey: key.rawValue) as! String
    }
}

enum PlistKey: String {
    
    case qiitaAuthToken = "QiitaAuthToken"
}
