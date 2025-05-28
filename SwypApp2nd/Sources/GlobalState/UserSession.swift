import Combine
import KakaoSDKUser
import Foundation

class UserSession: ObservableObject {
    static let shared = UserSession()
    
    /// 사용자 객체
    @Published var user: User?
    
    /// 앱 흐름
    @Published var appStep: AppStep = .splash
    

    /// 카카오 로그아웃
    func kakaoLogout(completion: @escaping (Bool) -> Void) {
        UserApi.shared.logout { error in
            if let error = error {
                print("❌ 카카오 로그아웃 실패: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            TokenManager.shared.clear(type: .kakao)
            self.logout() // 서버에서도 클리어
            completion(true)
        }
    }
    
    // 애플 로그아웃
    func appleLogout(completion: @escaping (Bool) -> Void) {
        
        TokenManager.shared.clear(type: .apple)
        self.logout() // 서버에서도 클리어
    }
    
    /// 로그인 상태 업데이트
    func updateUser(_ user: User) {
        DispatchQueue.main.async {
            print("🟢 [UserSession] updateUser 호출 - loginType 확인: \(user.loginType)")

            self.user = user
            
            // 로그인 타입에 따른 약관 동의 확인
            switch user.loginType {
            case .kakao:
                print("🟢 [UserSession] updateUser 호출 - didAgreeToTerms 값: \(UserDefaults.standard.bool(forKey: "didAgreeToKakaoTerms"))")
                let agreed = UserDefaults.standard.bool(
                    forKey: "didAgreeToKakaoTerms"
                )
                self.appStep = agreed ? .home : .terms
                print("🟢 [UserSession] appStep 설정됨: \(self.appStep)")

            case .apple:
                print("🟢 [UserSession] updateUser 호출 - didAgreeToTerms 값: \(UserDefaults.standard.bool(forKey: "didAgreeToAppleTerms"))")
                let agreed = UserDefaults.standard.bool(
                    forKey: "didAgreeToAppleTerms"
                )
                self.appStep = agreed ? .home : .terms
                print("🟢 [UserSession] appStep 설정됨: \(self.appStep)")
            }
        }
    }

    /// 로그아웃 처리
    func logout() {
        DispatchQueue.main.async {
            TokenManager.shared.clear(type: .server)  // 토큰 삭제
            self.user = nil
            self.appStep = .login
            print("🟢 [UserSession] appStep 설정됨: \(self.appStep)")
        }
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
            if UserDefaults.standard.didSeeOnboarding {
                self.appStep = .login
            } else {
                self.appStep = .onboarding
            }
            print("🟢 [UserSession] appStep 설정됨: \(self.appStep)")
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
            if let accessToken = TokenManager.shared.get(for: .server) {
                print("🟢 [UserSession] 서버 accessToken 존재 → 로그인 유지")
                
                let agreed = UserDefaults.standard.bool(forKey: "didAgreeToKakaoTerms")
                BackEndAuthService.shared.fetchMemberInfo(accessToken: accessToken) { result in
                    switch result {
                    case .success(let info):
                        print(
                            "🟢 [UserSession] fetchMemberInfo 성공 - 닉네임: \(info.nickname)"
                        )
                        
                        self.getUserCheckRate(accessToken: accessToken) { checkRate in
                            let user = User(
                                id: info.memberId,
                                name: info.nickname,
                                friends: [],
                                checkRate: checkRate,
                                loginType: .kakao,
                                serverAccessToken: accessToken,
                                serverRefreshToken: TokenManager.shared
                                    .get(for: .server, isRefresh: true) ?? ""
                            )
                            self.updateUser(user)
                        }
                    case .failure(let error):
                        print("🔴 [UserSession] 사용자 정보 조회 실패: \(error)")
                        self.logout()
                    }
                }
                
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
                            
                            BackEndAuthService.shared.fetchMemberInfo(accessToken: newAccessToken) { result in
                                switch result {
                                case .success(let info):
                                    self.getUserCheckRate(accessToken: newAccessToken) { checkRate in
                                        let user = User(
                                            id: info.memberId,
                                            name: info.nickname,
                                            friends: [],
                                            checkRate: checkRate,
                                            loginType: .kakao,
                                            serverAccessToken: newAccessToken,
                                            serverRefreshToken: refreshToken
                                        )
                                        self.updateUser(user)
                                    }
                                case .failure(let error):
                                    print(
                                        "🔴 [UserSession] 사용자 정보 조회 실패: \(error)"
                                    )
                                    self.logout()
                                }
                            }
                            
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
        if let accessToken = TokenManager.shared.get(for: .server) {
            print("🟢 [UserSession] 서버 accessToken 존재 → 로그인 유지")
            
            BackEndAuthService.shared.fetchMemberInfo(accessToken: accessToken) { result in
                switch result {
                case .success(let info):
                    print(
                        "🟢 [UserSession] fetchMemberInfo 성공 - 닉네임: \(info.nickname)"
                    )
                    
                    self.getUserCheckRate(accessToken: accessToken) { checkRate in
                        let user = User(
                            id: info.memberId,
                            name: info.nickname,
                            friends: [],
                            checkRate: checkRate,
                            loginType: .apple,
                            serverAccessToken: accessToken,
                            serverRefreshToken: TokenManager.shared
                                .get(for: .server, isRefresh: true) ?? ""
                        )
                        self.updateUser(user)
                    }
                    
                case .failure(let error):
                    print("🔴 [UserSession] 사용자 정보 조회 실패: \(error)")
                    self.logout()
                }
            }
            
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
                    BackEndAuthService.shared
                        .fetchMemberInfo(
                            accessToken: newAccessToken
                        ) { result in
                            switch result {
                            case .success(let info):
                                
                                self.getUserCheckRate(accessToken: newAccessToken) { checkRate in
                                    let user = User(
                                        id: info.memberId,
                                        name: info.nickname,
                                        friends: [],
                                        checkRate: checkRate,
                                        loginType: .apple,
                                        serverAccessToken: newAccessToken,
                                        serverRefreshToken: refreshToken
                                    )
                                    self.updateUser(user)
                                }
                                
                            case .failure(let error):
                                print("🔴 [UserSession] 사용자 정보 조회 실패: \(error)")
                                self.logout()
                            }
                        }
                case .failure(let error):
                    print("🔴 [UserSession] 서버 토큰 재발급 실패: \(error.localizedDescription)")
                    self.logout()
                }
            }
        }
    }
    
    func withdraw(loginType: LoginType, selectedReason: String, customReason: String, completion: @escaping (Bool) -> Void) {
        guard let accessToken = TokenManager.shared.get(for: .server) else {
            print("🔴 [UserSession] accessToken 없음")
            completion(false)
            return
        }

        BackEndAuthService.shared.withdraw(
            accessToken: accessToken,
            selectedReason: selectedReason,
            customReason: customReason
        ) { result in
            switch result {
            case .success:
                // 1. 토큰 삭제
                if loginType == .kakao {
                    UserApi.shared.unlink {(error) in
                        if let error = error {
                            print(error)
                        }
                        else {
                            print("unlink() success.")
                        }
                    }
                    TokenManager.shared.clear(type: .kakao)
                    
                } else if loginType == .apple {
                    TokenManager.shared.clear(type: .apple)
                }
                

                // 2. 약관 동의 기록 삭제
                UserDefaults.standard.removeObject(forKey: "didAgreeToKakaoTerms")
                UserDefaults.standard.removeObject(forKey: "didAgreeToAppleTerms")

                // 3. 유저 세션 초기화
                self.logout()
                print("🟢 [UserSession] 탈퇴 성공")
                completion(true)

            case .failure(let error):
                print("🔴 [UserSession] 탈퇴 실패: \(error.localizedDescription)")
                completion(false)
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
                        "🟢 [UserSession] getUserCheckRate 성공 챙김률: \(success.checkRate)"
                    )
                    completion(success.checkRate)
                case .failure(let error):
                    print("🔴 [UserSession] getUserCheckRate 실패: \(error)")
                    completion(0)
                }
            }
    }
}
