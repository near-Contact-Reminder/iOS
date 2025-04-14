import Foundation
import KakaoSDKAuth
import XCTest
//import Alamofire
//@testable import SwypApp2nd
//
//final class SwypApp2ndTests: XCTestCase {
//    func test_twoPlusTwo_isFour() {
//        XCTAssertEqual(2+2, 4)
//    }
//}
//
///// 토큰 저장 테스트
//final class TokenManagerTests: XCTestCase {
//    
//    let manager = TokenManager.shared
//
//    override func setUp() {
//        super.setUp()
//        manager.clear(type: .server)
//    }
//
//    func testSaveAndGetAccessToken() {
//        let token = "sampleAccessToken"
//        manager.save(token: token, for: .server)
//
//        let stored = manager.get(for: .server)
//
//        XCTAssertEqual(stored, token)
//    }
//
//    func testSaveAndGetRefreshToken() {
//        let token = "sampleRefreshToken"
//        manager.save(token: token, for: .server, isRefresh: true)
//
//        let stored = manager.get(for: .server, isRefresh: true)
//
//        XCTAssertEqual(stored, token)
//    }
//
//    func testClearToken() {
//        manager.save(token: "token", for: .server)
//        manager.save(token: "refresh", for: .server, isRefresh: true)
//
//        manager.clear(type: .server)
//
//        XCTAssertNil(manager.get(for: .server))
//        XCTAssertNil(manager.get(for: .server, isRefresh: true))
//    }
//}
//
///// 리프레시 토큰 테스트
//final class BackEndAuthServiceTests: XCTestCase {
//
//    func testRefreshAccessToken_Success() {
//        TokenManager.shared.save(token: "유효한 Refresh 토큰값 넣으면 가능", for: .server, isRefresh: true)
//        
//        guard let validRefreshToken = TokenManager.shared.get(for: .server, isRefresh: true) else {
//                XCTFail("🔴 저장된 refreshToken이 없음")
//                return
//            }
//
//        let expectation = self.expectation(description: "AccessToken 갱신 성공")
//
//        BackEndAuthService.shared.refreshAccessToken(refreshToken: validRefreshToken) { result in
//            switch result {
//            case .success(let accessToken):
//                print("🟢 accessToken 갱신 성공: \(accessToken)")
//                XCTAssertFalse(accessToken.isEmpty)
//            case .failure(let error):
//                XCTFail("\n🔴 accessToken 갱신 실패: \(error.localizedDescription)")
//            }
//            expectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 5.0)
//    }
//}
//
//
//final class ContactFrequencySettingsViewModelTests: XCTestCase {
//    var viewModel: ContactFrequencySettingsViewModel!
//
//    override func setUp() {
//        super.setUp()
//        viewModel = ContactFrequencySettingsViewModel()
//
//        // 임시 사용자 토큰 설정
//        let mockUser = User(
//            id: "user-id",
//            name: "Test User",
//            email: "test@example.com",
//            profileImageURL: nil,
//            friends: [],
//            loginType: .kakao,
//            serverAccessToken: "",
//            serverRefreshToken: "REFRESH_TOKEN"
//        )
//        UserSession.shared.user = mockUser
//    }
//
//    func testUploadAllFriendsToServer() {
//        // Given: 테스트용 Friend
//        let friend = Friend(
//            id: UUID(),
//            name: "테스트 친구",
//            image: UIImage(systemName: "person"),
//            imageURL: nil,
//            source: .kakao,
//            frequency: .weekly,
//            remindCategory: nil,
//            phoneNumber: "01012345678",
//            relationship: "친구",
//            birthDay: Date(),
//            anniversary: nil,
//            memo: "테스트 메모",
//            nextContactAt: Date(),
//            lastContactAt: nil,
//            checkRate: nil,
//            position: 1
//        )
//
//        let expectation = self.expectation(description: "업로드 완료")
//        
//        print("📦 테스트 시작: 서버에 Friend 업로드를 시도합니다.")
//        
//        // When
//        viewModel.uploadAllFriendsToServer([friend])
//
//        // 서버에 전송 확인은 콘솔 출력 or 로그 확인 필요
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//            print("🟢 테스트 완료: 서버 응답 로그를 확인하세요.")
//            expectation.fulfill()
//        }
//
//        // Then
//        waitForExpectations(timeout: 5.0, handler: nil)
//    }
//}
