import AuthenticationServices
import Foundation
import Combine
import KakaoSDKUser

class LoginViewModel: ObservableObject {

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
                    if (oauthToken?.accessToken) != nil {
                        // 서버에서 유저정보 반환 받기
                        print("카카오 로그인 성공 토큰: \(String(describing: oauthToken?.accessToken))")
                        
                        // TODO: - 로그인 성공후 id, name 생각하기.
                        let user = User(id: "", name: "", loginType: .kakao)
                        DispatchQueue.main.async {
                            UserSession.shared.isLoggedIn = true
                            UserSession.shared.updateUser(user)
                        }
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
                    if (oauthToken?.accessToken) != nil {
                        // 서버에서 유저정보 반환 받기
                        print("카카오 로그인 성공 토큰: \(String(describing: oauthToken?.accessToken))")
                        
                        // TODO: - 로그인 성공후 id, name 생각하기.
                        let user = User(id: "", name: "", loginType: .kakao)
                        DispatchQueue.main.async {
                            UserSession.shared.isLoggedIn = true
                            UserSession.shared.updateUser(user)
                        }
                    }
                    
                }
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
                let fullName = appleIDCredential.fullName
                let name =  (fullName?.familyName ?? "") + (
                    fullName?.givenName ?? ""
                )
                let email = appleIDCredential.email
                let IdentityToken = String(
                    data: appleIDCredential.identityToken!,
                    encoding: .utf8
                )
                let AuthorizationCode = String(
                    data: appleIDCredential.authorizationCode!,
                    encoding: .utf8
                )
                
                if let tokenData = identityToken, let tokenString = String(
                    data: tokenData,
                    encoding: .utf8
                ) {
                    sendToServer(userId: userId, identityToken: tokenString)
                    print("애플 로그인 성공 identityToken: \(String(describing: tokenString))")
                    print("애플 로그인 성공 AuthorizationCode: \(String(describing: AuthorizationCode))")
                    
                    // TODO: - 로그인 성공후 id, name 생각하기.
                    let user = User(id: "", name: "", loginType: .apple)
                    DispatchQueue.main.async {
                        UserSession.shared.isLoggedIn = true
                        UserSession.shared.updateUser(user)
                    }
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
                // 서버에서 받은 데이터..
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
