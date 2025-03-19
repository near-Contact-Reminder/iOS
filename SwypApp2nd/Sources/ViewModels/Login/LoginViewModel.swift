import AuthenticationServices
import Foundation
import Combine
import KakaoSDKUser

class LoginViewModel: ObservableObject {
    @Published var isLogin = false
    private var cancellable = Set<AnyCancellable>()
    
    // MARK: - KakaoLogin
    // TODO: - 카카오계정 가입 후 로그인 추후 진행
    /// 카카오톡 로그인 로직
    func loginWithKakaoAccount() {
        if (UserApi.isKakaoTalkLoginAvailable()) {
            // 카카오톡 앱으로 로그인
            UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                if let error = error {
                    print(error)
                }
                else {
                    print("loginWithKakaoAccount() success.")
                    // TODO: - 성공 시 동작 구현 서버와 연동
                    if let accessToken = oauthToken?.accessToken {
                        // 서버에서 유저정보 반환 받기
                    }
                }
            }
        } else {
            // 카카오톡 웹으로 로그인
            UserApi.shared.loginWithKakaoAccount{ oauthToken, error in
                if let error = error {
                    print(error)
                }
                else {
                    print("loginWithKakaoAccount() success.")
                    // TODO: - 성공 시 동작 구현 서버와 연동
                    if let accessToken = oauthToken?.accessToken {
                        // 서버에서 유저정보 반환 받기
                    }
                    
                }
            }
        }
    }
    
    func logoutWithKakaoAccount() {
        UserApi.shared.logout {(error) in
            if let error = error {
                print(error)
            }
            else {
                print("logout() success.")
            }
        }
    }
    
    // MARK: - AppleLogin
    func handleAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email] // 이름, 이메일 요청
    }

    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                let userId = appleIDCredential.user
                let identityToken = appleIDCredential.identityToken
                let authorizationCode = appleIDCredential.authorizationCode

                if let tokenData = identityToken, let tokenString = String(
                    data: tokenData,
                    encoding: .utf8
                ) {
                    sendToServer(userId: userId, identityToken: tokenString)
                }
            }
        case .failure(let error):
            print("Apple Login Error : \(error.localizedDescription)")
        }
    }

    private func sendToServer(userId: String, identityToken: String) {
        AuthService.shared
            .requestAppleLogin(userId: userId, identityToken: identityToken)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("server certification fali error: \(error.localizedDescription)")
                }
            }, receiveValue: { success in
                self.isLogin = success
            })
            .store(in: &cancellable)
    }
}

class AuthService {
    static let shared = AuthService()

    func requestAppleLogin(userId: String, identityToken: String) -> AnyPublisher<Bool, Error> {
        let url = URL(string: "서버url")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "user_id": userId,
            "identity_token": identityToken
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return true
            }
            .eraseToAnyPublisher()
    }
}
