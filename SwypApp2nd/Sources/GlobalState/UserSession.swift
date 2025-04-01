import Combine
import KakaoSDKUser
import Foundation

class UserSession: ObservableObject {
    static let shared = UserSession()
    
    @Published var user: User?
    
    /// 로그인 유무
    @Published var isLoggedIn = false
    
    /// 약관 동의 유무
    @Published var shouldShowTerms: Bool = false

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
        self.shouldShowTerms = !UserDefaults.standard.bool(forKey: "didAgreeToTerms")
    }

    /// 로그아웃 처리
    func logout() {
        // TODO: - SNS 로그아웃 추가하기.
        TokenManager.shared.clear(type: .server)  // 토큰 삭제
        self.user = nil
        self.isLoggedIn = false
    }
    
    /// 자동 로그인
    func tryAutoLogin() {
        if let _ = TokenManager.shared.get(for: .kakao) {
            // 카카오 로그인인 경우
            tryKakaoAutoLogin()
        } else if let _ = TokenManager.shared.get(for: .apple) {
            // 애플 로그인인 경우
            tryAppleAutoLogin()
        } else {
            print("🔴 [UserSession] 저장된 SNS 토큰이 없음, 로그인 필요")
        }
    }
    
    /// 카카오 토큰 검사
    func tryKakaoAutoLogin() {
        print("🟡 [UserSession] 카카오 로그인 시도")

        // 카카오 access token 유효성 검사
        UserApi.shared.accessTokenInfo { _, error in
            if let error = error {
                print("🔴 [UserSession] 카카오 accessToken 유효하지 않음: \(error.localizedDescription)")
                self.logout()
                return
            }

            print("🟢 [UserSession] 카카오 accessToken 유효")

            // 서버 accessToken 존재 여부 확인
            if TokenManager.shared.get(for: .server) != nil {
                print("🟢 [UserSession] 서버 accessToken 존재 → 로그인 유지")
                self.isLoggedIn = true
                return
            }

            // 서버 refreshToken 존재 여부 확인
            guard let refreshToken = TokenManager.shared.get(for: .server, isRefresh: true) else {
                print("🔴 [UserSession] 서버 refreshToken 없음 → 로그인 필요")
                self.logout()
                return
            }

            print("🟡 [UserSession] 서버 accessToken 없음 → refreshToken으로 재발급 시도")

            // 서버 토큰 재발급 요청
            BackEndAuthService.shared
                .refreshAccessToken(refreshToken: refreshToken) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let newAccessToken):
                            print("🟢 [UserSession] 서버 accessToken 재발급 성공")
                            TokenManager.shared
                                .save(token: newAccessToken, for: .server)
                            self.isLoggedIn = true
                        case .failure(let error):
                            print("🔴 [UserSession] 서버 토큰 재발급 실패: \(error.localizedDescription)")
                            self.logout()
                        }
                    }
                }
        }
    }
    
    /// 애플 토큰 검사
    func tryAppleAutoLogin() {
        print("🟡 [UserSession] 애플 로그인 시도")

        // 저장된 identityToken 가져오기
        guard TokenManager.shared.get(for: .apple) != nil else {
            print("🔴 [UserSession] 애플 identityToken 없음 → 로그인 필요")
            self.logout()
            return
        }

        // 서버 accessToken 확인
        if TokenManager.shared.get(for: .server) != nil {
            print("🟢 [UserSession] 서버 accessToken 존재 → 로그인 유지")
            self.isLoggedIn = true
            return
        }

        // 서버 refreshToken 확인
        guard let refreshToken = TokenManager.shared.get(for: .server, isRefresh: true) else {
            print("🔴 [UserSession] 서버 refreshToken 없음 → 로그인 필요")
            self.logout()
            return
        }

        print("🟡 [UserSession] 서버 accessToken 없음 → refreshToken으로 재발급 시도")
        // 서버 토큰 재발급
        BackEndAuthService.shared.refreshAccessToken(refreshToken: refreshToken) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newAccessToken):
                    print("🟢 [UserSession] 서버 accessToken 재발급 성공")
                    TokenManager.shared.save(token: newAccessToken, for: .server)
                    self.isLoggedIn = true
                case .failure(let error):
                    print("🔴 [UserSession] 서버 토큰 재발급 실패: \(error.localizedDescription)")
                    self.logout()
                }
            }
        }
    }
}
