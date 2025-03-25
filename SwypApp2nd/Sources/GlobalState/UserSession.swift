import Combine
import Foundation

class UserSession: ObservableObject {
    static let shared = UserSession()
    
    @Published var isLoggedIn = false
    @Published var user: User?

    func kakaoLogout() {
        self.user = nil
        self.isLoggedIn = false
    }
    
    func appleLogout() {
        self.user = nil
        self.isLoggedIn = false
    }
    /// 로그인 상태 업데이트
    func updateUser(_ user: User) {
        self.user = user
        self.isLoggedIn = true
    }

    /// 로그아웃 처리
    func logout() {
        // TODO: - SNS 로그아웃 추가하기.
        TokenManager.shared.clear(type: .server)  // 토큰 삭제
        self.user = nil
        self.isLoggedIn = false
    }
}
