import AuthenticationServices
import Foundation
import Combine
import KakaoSDKUser

class LoginViewModel: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
       
    private var cancellables = Set<AnyCancellable>()

    // 로그인 후 UserSession 업데이트
    private func updateUserSession(with user: User) {
        DispatchQueue.main.async {
            UserSession.shared.updateUser(user)
            UserSession.shared.isLoggedIn = true
        }
    }
       
    // MARK: - 카카오 로그인 흐름
    func loginWithKakao() {
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
                    case .success(let user):
                        // 서버 토큰 저장
                        TokenManager.shared
                            .save(token: user.serverAccessToken, for: .server)
                        TokenManager.shared
                            .save(
                                token: user.serverRefreshToken,
                                for: .server,
                                isRefresh: true
                            )
                        self.updateUserSession(with: user)
                    case .failure(let error):
                        self.errorMessage = "서버 로그인 실패: \(error.localizedDescription)"
                    }
                }
            
            // TODO: - Test (서버연결이 안되어있어 UserSession의 isLoggedIn변경이 안됨)
            let user = User(id: "", name: "", loginType: .kakao, serverAccessToken: "", serverRefreshToken: "")
            self.updateUserSession(with: user)
        }
    }

    // MARK: - 애플 로그인 요청 세팅
    func handleAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        SnsAuthService.shared.configureAppleRequest(request)
    }

    // MARK: - 애플 로그인 흐름
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        SnsAuthService.shared
            .handleAppleResult(result) {
                userId,
                identityToken in
                guard let userId = userId,
                      let identityToken = identityToken else {
                    self.errorMessage = "애플 로그인 실패"
                    self.isLoading = false
                    return
                }

                // 1. 토큰 저장 (애플은 identityToken만)
                TokenManager.shared.save(token: identityToken, for: .apple)

                // 2. 서버에 로그인 요청
                BackEndAuthService.shared
                    .loginWithApple(
                        userId: userId,
                        identityToken: identityToken
                    ) { result in
                        self.isLoading = false
                        switch result {
                        case .success(let user):
                            TokenManager.shared
                                .save(
                                    token: user.serverAccessToken,
                                    for: .server
                                )
                            TokenManager.shared
                                .save(
                                    token: user.serverRefreshToken,
                                    for: .server,
                                    isRefresh: true
                                )
                            self.updateUserSession(with: user)
                        case .failure(let error):
                            self.errorMessage = "서버 로그인 실패: \(error.localizedDescription)"
                        }
                    }
                // TODO: - Test (서버연결이 안되어있어 UserSession의 isLoggedIn변경이 안됨)
                let user = User(id: "", name: "", loginType: .kakao, serverAccessToken: "", serverRefreshToken: "")
                self.updateUserSession(with: user)
            }
    }
}
