//
//  QiitaUserSearchViewModel.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/14.
//

import SwiftData

@MainActor
final class QiitaUserSearchViewModel {
    
    // MARK: - public property
    
    var stateObserver: AsyncStream<ViewState>?
    
    // MARK: - private property
    
    private var continuation: AsyncStream<ViewState>.Continuation?
    /// 入力中の検索文字
    private var searchText = ""
    private var wordList: [SearchWordModel] = []
    
    // MARK: dependency
    
    private let searchWordRepository: SearchWordRepository
    private let qiitaUserRepository: QiitaUserRepository
    
    init(context: ModelContext, apiClient: ApiClient = QiitaApiClientImpl()) {
        
        self.searchWordRepository = SearchWordRepository(context: context)
        self.qiitaUserRepository = QiitaUserRepository(client: apiClient)
        self.stateObserver = AsyncStream { [weak self] continuation in
            
            self?.continuation = continuation
            continuation.yield(.initial(state: .initial))
        }
    }
    
    // MARK: - event
    
    /// 画面表示前の処理
    func viewDidLoad() {
        
        log.info("[In]")
        
        // 過去の検索ワードを取得
        wordList = (try? searchWordRepository.fetchAll()) ?? []
        continuation?.yield(.didAppear(state: ViewStateEntity(searchText: searchText,
                                                              postSearchTextList: wordList.map { $0.word })))
    }
    
    /// 画面非表示時の処理
    func viewDissapper() {
        
        log.info("[In]")
        continuation?.finish()
    }
    
    /// 検索テキストフィールドに文字入力時の処理
    func didEnterTextField(_ text: String) {
        
        log.info("[In] text: \(text)")
    }
    
    /// 検索ボタンタップ時のボタン
    func tappedSearchButton() {
        
        log.info("[In]")
    }
}

// MARK: - view state definition

extension QiitaUserSearchViewModel {
    
    enum ViewState: Equatable {
        
        case initial(state: ViewStateEntity)
        case didAppear(state: ViewStateEntity)
        case loading
        case screenTransition(user: QiitaUserModel)
        case alert(alert: AlertCase)
    }
    
    struct ViewStateEntity: Equatable {
        
        /// 検索ボタンが使用可能か
        let isEnabledSearchButton: Bool
        /// Qiitaのユーザーリスト
        let userList: [String]
        /// 過去の検索ワード
        let postSearchTextList: [String]
        
        static let initial = ViewStateEntity(isEnabledSearchButton: false)
        
        init(isEnabledSearchButton: Bool, userList: [String] = [], postSearchTextList: [String] = []) {
            
            self.isEnabledSearchButton = isEnabledSearchButton
            self.userList = userList
            self.postSearchTextList = postSearchTextList
        }
        
        init(searchText: String, userList: [String] = [], postSearchTextList: [String] = []) {
            
            self.isEnabledSearchButton = !searchText.isEmpty
            self.userList = userList
            self.postSearchTextList = postSearchTextList
        }
    }
}
