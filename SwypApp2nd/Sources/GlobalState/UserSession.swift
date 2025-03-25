import Combine
import Foundation

class UserSession: ObservableObject {
    static let shared = UserSession()
    
    @Published var isLoggedIn = false
    @Published var user: User?
    
    private let userDefaults = UserDefaults.standard
    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    func kakaoLogout() {
        self.user = nil
        self.isLoggedIn = false
    }
    
    func appleLogout() {
        self.user = nil
        self.isLoggedIn = false
    }
    
    // MARK: - Tokken Logic
    /// 토큰 저장
    func saveTokens(accessToken: String, refreshToken: String) {
        userDefaults.set(accessToken, forKey: Keys.accessToken)
        userDefaults.set(refreshToken, forKey: Keys.refreshToken)
    }

    /// 토큰 불러오기
    func getTokens() -> (accessToken: String?, refreshToken: String?) {
        let accessToken = userDefaults.string(forKey: Keys.accessToken)
        let refreshToken = userDefaults.string(forKey: Keys.refreshToken)
        return (accessToken, refreshToken)
    }

    /// 토큰 삭제
    func clearTokens() {
        userDefaults.removeObject(forKey: Keys.accessToken)
        userDefaults.removeObject(forKey: Keys.refreshToken)
    }

    /// 로그인 상태 업데이트
    func updateUser(_ user: User) {
        self.user = user
        self.isLoggedIn = true
    }

    /// 로그아웃 처리
    func logout() {
        clearTokens()  // 토큰 삭제
        self.user = nil
        self.isLoggedIn = false
    }

    /// 토큰 갱신
    func refreshAccessToken() {
        // TODO: - 만료된 access token을 refresh token으로 갱신
    }
}
