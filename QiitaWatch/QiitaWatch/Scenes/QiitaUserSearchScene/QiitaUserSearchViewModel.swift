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
    /// 過去の検索文字のモデルリスト
    private var searchWordModelList: [SearchWordModel] = [] {
        
        didSet {
            
            wordList = searchWordModelList.map { $0.word }
        }
    }
    /// 過去の検索文字リスト
    private var wordList: [String] = []
    
    // MARK: dependency
    
    private let searchWordRepository: SearchWordRepository
    private let qiitaUserRepository: QiitaUserRepository
    
    // MARK: - initialize method
    
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
        searchWordModelList = fetchCurrentSearchWordList()
        continuation?.yield(.appeared(state: ViewStateEntity(searchText: searchText,
                                                             postSearchTextList: wordList)))
    }
    
    /// 画面非表示時の処理
    func viewDissapper() {
        
        log.info("[In]")
        continuation?.finish()
    }
    
    /// 検索テキストフィールドに文字入力時の処理
    func didEnterTextField(_ text: String) {
        
        log.info("[In] text: \(text)")
        searchText = text
        continuation?.yield(.appeared(state: .init(searchText: text, postSearchTextList: wordList)))
    }
    
    /// 検索ボタンタップ時のボタン
    func tappedSearchButton() async {
        
        log.info("Start loading.")
        continuation?.yield(.loading)
        
        // 入力した文字を保存して最新の検索リストを取得する
        saveSearchWord(searchText)
        searchWordModelList = fetchCurrentSearchWordList()
        
        do {
            
            let fetchedUser = try await qiitaUserRepository.fetchByUserId(searchText)
            
            log.debug("Complete fetched user: \(fetchedUser).")
            continuation?.yield(.screenTransition(user: fetchedUser))
        }
        catch {
            
            handleFetchQiitaUserError(error)
        }
    }
}

// MARK: - private method

private extension QiitaUserSearchViewModel {
    
    func handleFetchQiitaUserError(_ error: QiitaUserRepository.FetchError) {
        
        let handler: @Sendable () -> Void = { [continuation, searchText, wordList] in
            
            continuation?.yield(.appeared(state: .init(searchText: searchText,
                                                        postSearchTextList: wordList)))
        }
        
        var alertCase: AlertCase
        
        log.error("error: \(error)")
        
        switch error {
            
        case .networkError:
            alertCase = .networkError(firstHandler: handler)
            
        case .noHitUser:
            alertCase = .noHitQiitaUser(firstHandler: handler)
        }
        
        continuation?.yield(.alert(alert: alertCase))
    }
    
    func fetchCurrentSearchWordList() -> [SearchWordModel] {
        
        return (try? searchWordRepository.fetchAll()) ?? []
    }
    
    func saveSearchWord(_ text: String) {
        
        do {
            
            try searchWordRepository.insertOrUpdate(text)
            log.info("Complete insert or update(text=\(text)).")
        }
        catch {
            
            log.error("Failed update: \(error).")
        }
    }
}

// MARK: - view state definition

extension QiitaUserSearchViewModel {
    
    enum ViewState: Equatable {
        
        /// 初期状態
        case initial(state: ViewStateEntity)
        /// 画面表示中
        case appeared(state: ViewStateEntity)
        /// ロード中
        case loading
        /// 画面遷移中
        case screenTransition(user: QiitaUserModel)
        /// アラート表示中
        case alert(alert: AlertCase)
    }
    
    struct ViewStateEntity: Equatable {
        
        /// 検索ボタンが使用可能か
        let isEnabledSearchButton: Bool
        /// 過去の検索ワード
        let postSearchTextList: [String]
        
        static let initial = ViewStateEntity(isEnabledSearchButton: false)
        
        init(isEnabledSearchButton: Bool, postSearchTextList: [String] = []) {
            
            self.isEnabledSearchButton = isEnabledSearchButton
            self.postSearchTextList = postSearchTextList
        }
        
        init(searchText: String, postSearchTextList: [String] = []) {
            
            self.isEnabledSearchButton = !searchText.isEmpty
            self.postSearchTextList = postSearchTextList
        }
    }
}
