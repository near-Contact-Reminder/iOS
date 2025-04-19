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
                    guard let oauthToken = oauthToken else { return }
                    self.requestAdditionalKakaoScopesIfNeeded(oauthToken)
                    completion(oauthToken)
                }
            }
        }
    }
    
    /// 카카오 동의 요청
    func requestAdditionalKakaoScopesIfNeeded(
        _ token: OAuthToken
    ) {
        UserApi.shared.me { user, error in
            guard let kakaoAccount = user?.kakaoAccount else {
                print("사용자 정보 조회 실패 또는 누락")
                return
            }

            var scopes: [String] = []

            if kakaoAccount.profileNeedsAgreement == true { scopes.append("profile") }
            if kakaoAccount.nameNeedsAgreement == true { scopes.append("name") }
            if kakaoAccount.profileImageNeedsAgreement == true { scopes.append("profile_image") }

            if scopes.isEmpty {
                print("🟢 [SnsAuthService] 추가 동의 필요 없음")
            } else {
                print("🟡 [SnsAuthService] 추가 동의 필요: \(scopes)")
                UserApi.shared.loginWithKakaoAccount(scopes: scopes) { newToken, error in
                    if let error = error {
                        print("🔴 [SnsAuthService] 추가 동의 실패: \(error)")
                    } else {
                    }
                }
            }
        }
    }
    
    /// 카카오 이미지 저장
    func downloadImageData(from urlString: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("🔴 [SnsAuthService] 잘못된 URL")
            completion(nil)
            return
        }
        
        AF.request(url)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    print("🟢 [SnsAuthService] 이미지 다운로드 성공, size: \(data.count) bytes")
                    completion(data)
                case .failure(let error):
                    print("🔴 [SnsAuthService] 이미지 다운로드 실패: \(error)")
                    completion(nil)
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
