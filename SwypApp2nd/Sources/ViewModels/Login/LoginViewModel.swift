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
    // TODO: - 애플 로그인 추가
}
