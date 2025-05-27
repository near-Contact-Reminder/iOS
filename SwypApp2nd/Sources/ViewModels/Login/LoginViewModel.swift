import AuthenticationServices
import Foundation
import Combine
import KakaoSDKUser
import FirebaseAnalytics

class LoginViewModel: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
       
    private var cancellables = Set<AnyCancellable>()

    // 로그인 후 UserSession 업데이트
    private func updateUserSession(with user: User) {
            print("🟢 [LoginViewModel] updateUserSession 호출됨")
            UserSession.shared.updateUser(user)
    }
       
    // MARK: - 카카오 로그인 흐름
    func loginWithKakao() {
        AnalyticsManager.shared.kakaoLoginLogAnalytics()
        
        isLoading = true
        SnsAuthService.shared.loginWithKakao { oauthToken in
            guard let token = oauthToken else {
                self.errorMessage = "카카오 로그인 실패"
                self.isLoading = false
                return
            }

            // 1. 토큰 저장
            TokenManager.shared.save(token: token.accessToken, for: .kakao)
            TokenManager.shared
                .save(token: token.refreshToken, for: .kakao, isRefresh: true)

            // 2. 서버 로그인 요청
            BackEndAuthService.shared
                .loginWithKakao(accessToken: token.accessToken) { result in
                    self.isLoading = false
                    switch result {
                    case .success(let tokenResponse):
                        
                        // 서버 토큰 저장
                        TokenManager.shared
                            .save(token: tokenResponse.accessToken, for: .server)
                        TokenManager.shared
                            .save(
                                token: tokenResponse.refreshTokenInfo.token,
                                for: .server,
                                isRefresh: true
                            )
                        
                        BackEndAuthService.shared
                            .fetchMemberInfo(accessToken: tokenResponse.accessToken) { result in
                                switch result {
                                case .success(let userInfo):
                                    print("🟢 자동 로그인 성공: \(userInfo.nickname)")
                                    self.getUserCheckRate(accessToken: tokenResponse.accessToken) { checkRate in
                                        let user = User(
                                            id: userInfo.memberId,
                                            name: userInfo.nickname,
                                            friends: [],
                                            checkRate: checkRate,
                                            loginType: .kakao,
                                            serverAccessToken: tokenResponse.accessToken,
                                            serverRefreshToken: tokenResponse.refreshTokenInfo.token
                                        )
                                        self.updateUserSession(with: user)
                                    }
                                case .failure(let error):
                                    print("🔴 자동 로그인 실패: \(error)")
                                }
                            }
                    case .failure(let error):
                        self.errorMessage = "서버 로그인 실패: \(error.localizedDescription)"
                    }
                }
        }
    }

    // MARK: - 애플 로그인 요청 세팅
    func handleAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        AnalyticsManager.shared.appleLoginLogAnalytics()
        SnsAuthService.shared.configureAppleRequest(request)
    }

    // MARK: - 애플 로그인 흐름
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        SnsAuthService.shared
            .handleAppleResult(result) { userId, identityToken, authorizationCode in
                guard let userId = userId,
                      let identityToken = identityToken,
                        let authorizationCode = authorizationCode else {
                    self.errorMessage = "애플 로그인 실패"
                    self.isLoading = false
                    return
                }

                // 1. 토큰 저장 (애플은 identityToken만)
                TokenManager.shared.save(token: identityToken, for: .apple)

                // 2. 서버에 로그인 요청
                BackEndAuthService.shared
                    .loginWithApple(userId: userId, identityToken: identityToken, authorizationCode: authorizationCode) { result in
                        self.isLoading = false
                        switch result {
                        case .success(let tokenResponse):
                            
                            TokenManager.shared
                                .save(
                                    token: tokenResponse.accessToken,
                                    for: .server
                                )
                            TokenManager.shared
                                .save(
                                    token: tokenResponse.refreshTokenInfo.token,
                                    for: .server,
                                    isRefresh: true
                                )
                            
                            BackEndAuthService.shared
                                .fetchMemberInfo(accessToken: tokenResponse.accessToken) { result in
                                    switch result {
                                    case .success(let userInfo):
                                        print("🟢 자동 로그인 성공: \(userInfo.nickname)")
                                        self.getUserCheckRate(accessToken: tokenResponse.accessToken) { checkRate in
                                            let user = User(
                                                id: userInfo.memberId,
                                                name: userInfo.nickname,
                                                friends: [],
                                                checkRate: checkRate,
                                                loginType: .apple,
                                                serverAccessToken: tokenResponse.accessToken,
                                                serverRefreshToken: tokenResponse.refreshTokenInfo.token
                                            )
                                            self.updateUserSession(with: user)
                                        }
                                    case .failure(let error):
                                        print("🔴 자동 로그인 실패: \(error)")
                                    }
                                }
                        case .failure(let error):
                            self.errorMessage = "서버 로그인 실패: \(error.localizedDescription)"
                        }
                    }
            }
    }
    
    // 유저의 챙김률
    func getUserCheckRate(accessToken: String, completion: @escaping (Int) -> Void) {
            
        BackEndAuthService.shared
            .getUserCheckRate(accessToken: accessToken) { result in
                switch result {
                case .success(let success):
                    print(
                        "🟢 [LoginViewModel] getUserCheckRate 성공 챙김률: \(success.checkRate)"
                    )
                    completion(success.checkRate)
                case .failure(let error):
                    print("🔴 [LoginViewModel] getUserCheckRate 실패: \(error)")
                    completion(0)
                }
            }
    }
}
