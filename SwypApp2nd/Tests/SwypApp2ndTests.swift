import Foundation
import KakaoSDKAuth
import XCTest
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
