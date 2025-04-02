import AuthenticationServices
import Alamofire
import Combine
import Foundation
import KakaoSDKUser
import KakaoSDKAuth

class SnsAuthService {
    static let shared = SnsAuthService()
    
    /// 카카오 로그인
    func loginWithKakao(
        completion: @escaping (_ oauthToken: OAuthToken?) -> Void
    ) {
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                if let error = error {
                    print("카카오톡 앱 로그인 실패:", error)
                    completion(nil)
                } else {
                    completion(oauthToken)
                }
            }
        } else {
            UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                if let error = error {
                    print("카카오 계정 로그인 실패:", error)
                    completion(nil)
                } else {
                    completion(oauthToken)
                }
            }
        }
    }

    /// 애플 로그인 요청 세팅
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    /// 애플 로그인 결과 처리
    func handleAppleResult(
        _ result: Result<ASAuthorization, Error>,
        completion: @escaping ( _ userId: String?, _ identityToken: String?, _ authorizationCode: String?) -> Void
    ) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential,
               let tokenData = credential.identityToken,
               let tokenString = String(data: tokenData, encoding: .utf8),
               let codeData = credential.authorizationCode,
               let codeString = String(data: codeData, encoding: .utf8) {
                print("🧪 [애플 토큰 테스트] tokenString: \(tokenString)")
                print("🧪 [애플 토큰 테스트] codeString: \(codeString)")
                completion(credential.user, tokenString, codeString)
            } else {
                completion(nil, nil, nil)
            }
        case .failure(let error):
            print("애플 로그인 실패: \(error)")
            completion(nil, nil, nil)
        }
    }
}
