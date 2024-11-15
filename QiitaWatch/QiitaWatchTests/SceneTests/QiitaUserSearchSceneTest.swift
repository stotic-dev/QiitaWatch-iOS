//
//  QiitaUserSearchSceneTest.swift
//  QiitaWatchTests
//
//  Created by 佐藤汰一 on 2024/11/14.
//

import Alamofire
import SwiftData
import XCTest

@testable import QiitaWatch

@MainActor
final class QiitaUserSearchSceneTest: XCTestCase {
    
    private let container = TestContainerFactory.initialize()
    private let defaultSearchWord = (1...9).map { String($0) }

    override func setUp() async throws {
        
        let defaultWordModel = defaultSearchWord.map { SearchWordModel(word: $0) }
        for model in defaultWordModel {
            
            container.mainContext.insert(model)
        }
    }
    
    override func tearDown() async throws {
        
        try container.mainContext.delete(model: SearchWordModel.self)
    }
}

extension QiitaUserSearchSceneTest {
    
    // MARK: - 正常系
    
    /// 画面表示時の処理を確認
    ///
    /// # 仕様
    /// - 過去の検索ワードを取得して表示する
    func testViewAppear() throws {
        
        let viewModel = QiitaUserSearchViewModel(context: container.mainContext)
        let expectation = expectation(description: "view state")
        guard let stateObserver = viewModel.stateObserver else {
            
            XCTFail()
            return
        }
        
        Task {
            
            await assertViewState(stateObserver,
                                  expectedStateStream: [
                                    .initial(state: .initial),
                                    .appeared(state: .init(isEnabledSearchButton: false,
                                                            postSearchTextList: defaultSearchWord.reversed()))
                                  ],
                                  expectation: expectation)
        }
        
        viewModel.viewDidLoad()
        viewModel.viewDissapper()
        wait(for: [expectation], timeout: 5)
    }
    
    /// 検索ボタン押下時の処理を確認
    ///
    /// # 仕様
    /// - テキストフィールドに何も入力されていない場合は、ボタンは非活性にする
    /// - テキストフィールドに文字が入力されている場合は、その文字でユーザーを取得する
    /// - ユーザー一覧取得後にテキストフィールドの文字を過去の検索ワードに保存する
    /// - ユーザーを取得できた場合は、ユーザー情報画面へ遷移する
    func testTappedSearchButton() async throws {
        
        let inputKeyword = "test"
        let expectedOutput = QiitaUserModel(id: UUID().uuidString,
                                            name: "test name",
                                            description: "xxxxxxxx",
                                            followees_count: 10,
                                            followers_count: 100,
                                            profile_image_url: "https://test.com/test.png")
        let mockApiClient = ApiClientMock(expectedInput: .fetchQiitaUsersService(keyword: inputKeyword),
                                          expectedResult: .success(expectedOutput))
        
        let viewModel = QiitaUserSearchViewModel(context: container.mainContext, apiClient: mockApiClient)
        let expectation = expectation(description: "view state")
        guard let stateObserver = viewModel.stateObserver else {
            
            XCTFail()
            return
        }
        
        Task {
            
            await assertViewState(stateObserver,
                                  expectedStateStream: [
                                    .initial(state: .initial), // 初期状態
                                    .appeared(state: .init(isEnabledSearchButton: false, postSearchTextList: defaultSearchWord.reversed())), // 画面表示後
                                    .appeared(state: .init(isEnabledSearchButton: true, postSearchTextList: defaultSearchWord.reversed())), // 文字入力
                                    .appeared(state: .init(isEnabledSearchButton: false, postSearchTextList: defaultSearchWord.reversed())), // 文字削除
                                    .appeared(state: .init(isEnabledSearchButton: true, postSearchTextList: defaultSearchWord.reversed())), // 文字入力
                                    .loading, // 検索ボタン押下後ロード中
                                    .screenTransition(user: expectedOutput) // ユーザー取得で画面遷移
                                  ],
                                  expectation: expectation)
        }
        
        viewModel.viewDidLoad()
        viewModel.didEnterTextField("xxx")
        viewModel.didEnterTextField("")
        viewModel.didEnterTextField(inputKeyword)
        await viewModel.tappedSearchButton()
        viewModel.viewDissapper()
    
        await fulfillment(of: [expectation], timeout: 5)
        
        // 検索ワードが保存されていることを確認
        let sortDescriptor = SortDescriptor<SearchWordModel>(\.createdAt, order: .reverse)
        let searchWords = try container.mainContext.fetch(FetchDescriptor<SearchWordModel>(sortBy: [sortDescriptor])).map { $0.word }
        var expectedSearchWords = defaultSearchWord.reversed().map(\.self)
        expectedSearchWords.insert(inputKeyword, at: .zero)
        XCTAssertEqual(searchWords, expectedSearchWords)
    }
    
    /// 検索ボタン押下時にユーザーの取得件数が0件の場合の処理確認
    ///
    /// # 仕様
    /// - ユーザーの取得件数が0件だった旨のアラートを表示する
    /// - 前回検索した文言で検索する場合、その文言を検索文字リストの一番前に表示するようにする
    func testEmptyFetchUserList() async throws {
        
        let inputKeyword = "6"

        let expectedError = AFError.responseSerializationFailed(reason: .decodingFailed(error: DecodingError.valueNotFound(String.self, .init(codingPath: [], debugDescription: ""))))
        let mockApiClient = ApiClientMock<QiitaUserModel>(expectedInput: .fetchQiitaUsersService(keyword: inputKeyword),
                                                          expectedResult: .failure(expectedError))
        
        let viewModel = QiitaUserSearchViewModel(context: container.mainContext, apiClient: mockApiClient)
        let expectation = expectation(description: "view state")
        guard let stateObserver = viewModel.stateObserver else {
            
            XCTFail()
            return
        }
        
        Task {
            
            await assertViewState(stateObserver,
                                  expectedStateStream: [
                                    .initial(state: .initial), // 初期状態
                                    .appeared(state: .init(isEnabledSearchButton: false, postSearchTextList: defaultSearchWord.reversed())), // 画面表示後
                                    .appeared(state: .init(isEnabledSearchButton: true, postSearchTextList: defaultSearchWord.reversed())), // 文字入力,
                                    .loading, // 検索ボタン押下後ロード中
                                    .alert(alert: .noHitQiitaUser(firstHandler: {})) // ユーザー取得できずアラート表示
                                  ],
                                  expectation: expectation)
        }
        
        viewModel.viewDidLoad()
        viewModel.didEnterTextField(inputKeyword)
        await viewModel.tappedSearchButton()
        viewModel.viewDissapper()
        
        await fulfillment(of: [expectation], timeout: 5)
        
        // 検索ワードが更新されていることを確認
        let sortDescriptor = SortDescriptor<SearchWordModel>(\.createdAt, order: .reverse)
        let searchWords = try container.mainContext.fetch(FetchDescriptor<SearchWordModel>(sortBy: [sortDescriptor])).map { $0.word }
        var expectedSearchWords = defaultSearchWord.reversed().map(\.self)
        expectedSearchWords.insert(expectedSearchWords.remove(at: expectedSearchWords.firstIndex(of: inputKeyword)!), at: .zero)
        XCTAssertEqual(searchWords, expectedSearchWords)
    }
    
    // MARK: - 異常系
    
    /// 検索ボタン押下時にネットワークなどの原因でユーザー取得に失敗した時の処理確認
    ///
    /// # 仕様
    /// - 通信に失敗した旨のアラートを表示する
    func testFailedFetchUserByNetwork() async throws {
        
        let inputKeyword = "test"

        let expectedError = AFError.explicitlyCancelled
        let mockApiClient = ApiClientMock<QiitaUserModel>(expectedInput: .fetchQiitaUsersService(keyword: inputKeyword),
                                                          expectedResult: .failure(expectedError))
        
        let viewModel = QiitaUserSearchViewModel(context: container.mainContext, apiClient: mockApiClient)
        let expectation = expectation(description: "view state")
        guard let stateObserver = viewModel.stateObserver else {
            
            XCTFail()
            return
        }
        
        Task {
            
            await assertViewState(stateObserver,
                                  expectedStateStream: [
                                    .initial(state: .initial), // 初期状態
                                    .appeared(state: .init(isEnabledSearchButton: false, postSearchTextList: defaultSearchWord.reversed())), // 画面表示後
                                    .appeared(state: .init(isEnabledSearchButton: true, postSearchTextList: defaultSearchWord.reversed())), // 文字入力
                                    .loading, // 検索ボタン押下後ロード中
                                    .alert(alert: .networkError(firstHandler: {})) // エラーによりアラート表示
                                  ],
                                  expectation: expectation)
        }
        
        viewModel.viewDidLoad()
        viewModel.didEnterTextField(inputKeyword)
        await viewModel.tappedSearchButton()
        viewModel.viewDissapper()
        
        await fulfillment(of: [expectation], timeout: 5)
    }
}

private extension QiitaUserSearchSceneTest {
    
    func assertViewState<State>(_ stream: AsyncStream<State>, expectedStateStream: [State], expectation: XCTestExpectation) async where State: Equatable, State: Sendable {
        
        var actualStateStream: [State] = []
        for await state in stream { actualStateStream.append(state) }
        
        guard actualStateStream.count == expectedStateStream.count else {
            
            XCTFail("Missing view state.(actual: \(actualStateStream) expected: \(expectedStateStream))")
            expectation.fulfill()
            return
        }
        
        actualStateStream.indices.forEach {
            
            print("asserting actual: \(actualStateStream[$0]) expected: \(expectedStateStream[$0])")
            XCTAssertEqual(actualStateStream[$0], expectedStateStream[$0])
        }
        
        expectation.fulfill()
    }
}
