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
                                    .didAppear(state: .init(isEnabledSearchButton: false,
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
    func testTappedSearchButton() throws {
        
        let inputKeyword = "test"
        guard let expectedApiInput: ApiService = .fetchQiitaUsersService(keyword: inputKeyword) else {
            
            XCTFail("Fail create input.")
            return
        }
        let expectedOutput = QiitaUserModel(id: UUID().uuidString,
                                            name: "test name",
                                            description: "xxxxxxxx",
                                            followees_count: 10,
                                            followers_count: 100,
                                            profile_image_url: "https://test.com/test.png")
        let mockApiClient = ApiClientMock(expectedInput: expectedApiInput,
                                          expectedResult: .success(expectedOutput))
        
        let viewModel = QiitaUserSearchViewModel(context: container.mainContext)
        let expectation = expectation(description: "view state")
        guard let stateObserver = viewModel.stateObserver else {
            
            XCTFail()
            return
        }
        
        Task {
            
            await assertViewState(stateObserver,
                                  expectedStateStream: [
                                    .initial(state: .initial), // 初期状態
                                    .didAppear(state: .init(isEnabledSearchButton: false, postSearchTextList: defaultSearchWord)), // 画面表示後
                                    .didAppear(state: .init(isEnabledSearchButton: true, postSearchTextList: defaultSearchWord)), // 文字入力
                                    .didAppear(state: .init(isEnabledSearchButton: false, postSearchTextList: defaultSearchWord)), // 文字削除
                                    .didAppear(state: .init(isEnabledSearchButton: true, postSearchTextList: defaultSearchWord)), // 文字入力
                                    .screenTransition(user: expectedOutput) // 検索ボタン押下後
                                  ],
                                  expectation: expectation)
        }
        
        viewModel.viewDidLoad()
        viewModel.didEnterTextField("xxx")
        viewModel.didEnterTextField("")
        viewModel.didEnterTextField(inputKeyword)
        viewModel.tappedSearchButton()
        viewModel.viewDissapper()
        
        wait(for: [expectation], timeout: 5)
        
        // 検索ワードが保存されていることを確認
        let sortDescriptor = SortDescriptor<SearchWordModel>(\.createdAt, order: .reverse)
        let searchWords = try container.mainContext.fetch(FetchDescriptor<SearchWordModel>(sortBy: [sortDescriptor])).map { $0.word }
        var expectedSearchWords = defaultSearchWord.reversed().map(\.self)
        expectedSearchWords.append(inputKeyword)
        XCTAssertEqual(searchWords, expectedSearchWords)
    }
    
    /// 検索ボタン押下時にユーザーの取得件数が0件の場合の処理確認
    ///
    /// # 仕様
    /// - ユーザーの取得件数が0件だった旨のアラートを表示する
    func testEmptyFetchUserList() throws {
        
        let inputKeyword = "test"
        guard let expectedApiInput: ApiService = .fetchQiitaUsersService(keyword: inputKeyword) else {
            
            XCTFail("Fail create input.")
            return
        }

        let expectedError = AFError.responseSerializationFailed(reason: .decodingFailed(error: DecodingError.valueNotFound(String.self, .init(codingPath: [], debugDescription: ""))))
        let mockApiClient = ApiClientMock<QiitaUserModel>(expectedInput: expectedApiInput,
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
                                    .didAppear(state: .init(isEnabledSearchButton: false, postSearchTextList: defaultSearchWord)), // 画面表示後
                                    .didAppear(state: .init(isEnabledSearchButton: true, postSearchTextList: defaultSearchWord)), // 文字入力
                                    .alert(alert: .noHitQiitaUser(firstHandler: {})) // 検索ボタン押下後
                                  ],
                                  expectation: expectation)
        }
        
        viewModel.viewDidLoad()
        viewModel.didEnterTextField(inputKeyword)
        viewModel.tappedSearchButton()
        viewModel.viewDissapper()
        
        wait(for: [expectation], timeout: 5)
    }
    
    // MARK: - 異常系
    
    /// 検索ボタン押下時にネットワークなどの原因でユーザー取得に失敗した時の処理確認
    ///
    /// # 仕様
    /// - 通信に失敗した旨のアラートを表示する
    func testFailedFetchUserByNetwork() throws {
        
        let inputKeyword = "test"
        guard let expectedApiInput: ApiService = .fetchQiitaUsersService(keyword: inputKeyword) else {
            
            XCTFail("Fail create input.")
            return
        }

        let expectedError = AFError.explicitlyCancelled
        let mockApiClient = ApiClientMock<QiitaUserModel>(expectedInput: expectedApiInput,
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
                                    .didAppear(state: .init(isEnabledSearchButton: false, postSearchTextList: defaultSearchWord)), // 画面表示後
                                    .didAppear(state: .init(isEnabledSearchButton: true, postSearchTextList: defaultSearchWord)), // 文字入力
                                    .alert(alert: .networkError(firstHandler: {})) // 検索ボタン押下後
                                  ],
                                  expectation: expectation)
        }
        
        viewModel.viewDidLoad()
        viewModel.didEnterTextField(inputKeyword)
        viewModel.tappedSearchButton()
        viewModel.viewDissapper()
        
        wait(for: [expectation], timeout: 5)
    }
    
    /// 検索ボタン押下時に入力した文字の原因でユーザー取得に失敗した時の処理確認
    ///
    /// # 仕様
    /// - 不正な入力があった旨のアラートを表示する
    func testFailedFetchUserByInputText() throws {
        
        let inputKeyword = "//////..////"
        
        let viewModel = QiitaUserSearchViewModel(context: container.mainContext)
        let expectation = expectation(description: "view state")
        guard let stateObserver = viewModel.stateObserver else {
            
            XCTFail()
            return
        }
        
        Task {
            
            await assertViewState(stateObserver,
                                  expectedStateStream: [
                                    .initial(state: .initial), // 初期状態
                                    .didAppear(state: .init(isEnabledSearchButton: false, postSearchTextList: defaultSearchWord)), // 画面表示後
                                    .didAppear(state: .init(isEnabledSearchButton: true, postSearchTextList: defaultSearchWord)), // 文字入力
                                    .alert(alert: .invalidInputOnTextField(firstHandler: {})) // 検索ボタン押下後
                                  ],
                                  expectation: expectation)
        }
        
        viewModel.viewDidLoad()
        viewModel.didEnterTextField(inputKeyword)
        viewModel.tappedSearchButton()
        viewModel.viewDissapper()
        
        wait(for: [expectation], timeout: 5)
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
