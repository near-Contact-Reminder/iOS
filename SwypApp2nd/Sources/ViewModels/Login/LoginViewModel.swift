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
            print("updateUserSession 호출됨")
            UserSession.shared.updateUser(user)
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
                        // TODO: - id, name 서버에서 받을건지 요청
                        let user = User(
                            id: "",
                            name: "",
                            loginType: .kakao,
                            serverAccessToken: tokenResponse.accessToken,
                            serverRefreshToken: tokenResponse.refreshTokenInfo.token
                        )
                        self.updateUserSession(with: user)
                    case .failure(let error):
                        self.errorMessage = "서버 로그인 실패: \(error.localizedDescription)"
                    }
                }
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
                            // TODO: - id, name 서버에서 받을건지 요청
                            let user = User(
                                id: "",
                                name: "",
                                loginType: .apple,
                                serverAccessToken: tokenResponse.accessToken,
                                serverRefreshToken: tokenResponse.refreshTokenInfo.token
                            )
                            self.updateUserSession(with: user)
                        case .failure(let error):
                            self.errorMessage = "서버 로그인 실패: \(error.localizedDescription)"
                        }
                    }
            }
    }
}
