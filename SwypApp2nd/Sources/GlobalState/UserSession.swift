import Combine
import UIKit
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
            self.evaluateTermsAgreement()
        }
    }
    
    private func evaluateTermsAgreement() {
        guard let accessToken = TokenManager.shared.get(for: .server) else {
            print("🔴 [UserSession] 서버 토큰 없음 - 약관 동의 상태를 확인할 수 없어 Terms 화면으로 이동")
            self.appStep = .home
            return
        }
        self.appStep = .home
        
        BackEndAuthService.shared.fetchMyTermsAgreements(accessToken: accessToken) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    let requiredAgreements = response.agreements.filter { $0.isRequired }
                    let allRequiredAgreed = requiredAgreements.allSatisfy { $0.isAgreed }
                    self.appStep = allRequiredAgreed ? .home : .terms
                    print("🟢 [UserSession] 약관 동의 확인 완료 - appStep: \(self.appStep)")
                case .failure(let error):
                    print("🔴 [UserSession] 약관 동의 상태 조회 실패: \(error.localizedDescription)")
                    self.appStep = .terms
                }
            }
        }
    }

    /// 로그아웃 처리
    func logout() {
        // TODO: pending notifications는 삭제가 아니라 일시 정지 해야 함
        NotificationManager.shared.clearNotifications()
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
            if error != nil {
                SnsAuthService.shared.tryAutoReLoginKakao { oauthToken in
                    guard let token = oauthToken else {
                        print("🔴 [UserSession] 카카오 자동 재로그인 실패")
                        self.logout()
                        return
                    }
                    // 토큰 저장
                    TokenManager.shared
                        .save(token: token.accessToken, for: .kakao)
                    TokenManager.shared
                        .save(
                            token: token.refreshToken,
                            for: .kakao,
                            isRefresh: true
                        )
                    // 서버에 소셜 로그인 요청
                    BackEndAuthService.shared
                        .loginWithKakao(
                            accessToken: token.accessToken
                        ) { result in
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
                                    .fetchMemberInfo(
                                        accessToken: tokenResponse.accessToken
                                    ) { result in
                                        switch result {
                                        case .success(let info):
                                            BackEndAuthService.shared.getUserCheckRate(
                                                accessToken: tokenResponse.accessToken
                                            ) { checkRate in
                                                let user = User(
                                                    id: info.memberId,
                                                    name: info.nickname,
                                                    friends: [],
                                                    checkRate: checkRate,
                                                    loginType: .kakao,
                                                    serverAccessToken: tokenResponse.accessToken,
                                                    serverRefreshToken: tokenResponse.refreshTokenInfo.token
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
                                print(
                                    "🔴 [UserSession] 서버 토큰 재발급 실패: \(error.localizedDescription)"
                                )
                                // 1. SNS 자동 재로그인 시도
                                SnsAuthService.shared
                                    .tryAutoReLoginKakao { oauthToken in
                                        guard let token = oauthToken else {
                                            self.logout()
                                            return
                                        }
                                        // 2. 서버에 소셜 로그인 요청
                                        BackEndAuthService.shared
                                            .loginWithKakao(
                                                accessToken: token.accessToken
                                            ) { result in
                                                switch result {
                                                case .success(
                                                    let tokenResponse
                                                ):
                                                    // 3. 서버 토큰 저장 및 세션 갱신
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
                                                        .fetchMemberInfo(
                                                            accessToken: tokenResponse.accessToken
                                                        ) { result in
                                                            switch result {
                                                            case .success(let info):
                                                                BackEndAuthService.shared.getUserCheckRate(
                                                                    accessToken: tokenResponse.accessToken
                                                                ) { checkRate in
                                                                    let user = User(
                                                                        id: info.memberId,
                                                                        name: info.nickname,
                                                                        friends: [],
                                                                        checkRate: checkRate,
                                                                        loginType: .kakao,
                                                                        serverAccessToken: tokenResponse.accessToken,
                                                                        serverRefreshToken: tokenResponse.refreshTokenInfo.token
                                                                    )
                                                                    self.updateUser(user)
                                                                }
                                                            case .failure(let error):
                                                                print("🔴 [UserSession] 사용자 정보 조회 실패: \(error)")
                                                                self.logout()
                                                            }
                                                        }
                                                case .failure:
                                                    self.logout()
                                                }
                                            }
                                    }
                            }
                        }
                }
                return
            }

            print("🟢 [UserSession] 카카오 accessToken 유효")

            // 서버 accessToken 존재 여부 확인
            if let accessToken = TokenManager.shared.get(for: .server) {
                print("🟢 [UserSession] 서버 accessToken 존재 → 로그인 유지")
                
                BackEndAuthService.shared.fetchMemberInfo(accessToken: accessToken) { result in
                    switch result {
                    case .success(let info):
                        print(
                            "🟢 [UserSession] fetchMemberInfo 성공 - 닉네임: \(info.nickname)"
                        )
                        
                        BackEndAuthService.shared.getUserCheckRate(accessToken: accessToken) { checkRate in
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
                        // accessToken 만료라면 refreshToken으로 재발급 시도
                        if let refreshToken = TokenManager.shared.get(for: .server, isRefresh: true) {
                            print("🟡 [UserSession] accessToken 만료 → refreshToken으로 재발급 시도")
                            BackEndAuthService.shared.refreshAccessToken(refreshToken: refreshToken) { result in
                                switch result {
                                case .success(let newAccessToken):
                                    print("🟢 [UserSession] 서버 accessToken 재발급 성공")
                                    TokenManager.shared.save(token: newAccessToken, for: .server)
                                    // 재시도
                                    self.tryAutoLogin()
                                case .failure(let error):
                                    print("🔴 [UserSession] 서버 토큰 재발급 실패: \(error.localizedDescription)")
                                    self.logout()
                                }
                            }
                        } else {
                            self.logout()
                        }
                    }
                }
                
                return
            }

            // 서버 accessToken이 없는 경우 - Kakao accessToken으로 서버 로그인
            if let kakaoAccessToken = TokenManager.shared.get(for: .kakao) {
                print("🟡 [UserSession] 서버 accessToken 없음 → loginWithKakao() 재시도")
                BackEndAuthService.shared.loginWithKakao(accessToken: kakaoAccessToken) { result in
                    switch result {
                    case .success(let tokenResponse):
                        TokenManager.shared.save(token: tokenResponse.accessToken, for: .server)
                        TokenManager.shared.save(token: tokenResponse.refreshTokenInfo.token,
                                                 for: .server,
                                                 isRefresh: true)
                        // 새 토큰으로 다시 자동 로그인 절차 진행
                        self.tryAutoLogin()
                    case .failure(let error):
                        print("🔴 [UserSession] 서버 로그인 실패: \(error.localizedDescription)")
                        self.logout()
                    }
                }
            } else {
                self.logout()
            }
            
        }
    }
    
    /// 애플 토큰 검사
    func tryAppleAutoLogin() {
        print("🟡 [UserSession] 애플 로그인 시도")
            
        // UIWindow를 presentationAnchor로 획득
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            print("🔴 [UserSession] UIWindow를 찾을 수 없음")
            self.logout()
            return
        }
            
        // 저장된 identityToken(애플 토큰) 확인
        guard TokenManager.shared.get(for: .apple) != nil else {
            // 토큰이 없으면 자동 재로그인 시도
            SnsAuthService.shared
                .tryAutoReLoginApple(
                    presentationAnchor: window
                ) {
                    userId,
                    identityToken,
                    authorizationCode in
                    guard let userId = userId,
                          let identityToken = identityToken,
                          let authorizationCode = authorizationCode else {
                        print("🔴 [UserSession] 애플 자동 재로그인 실패")
                        self.logout()
                        return
                    }
                    // 서버에 소셜 로그인 요청
                    BackEndAuthService.shared
                        .loginWithApple(
                            userId: userId,
                            identityToken: identityToken,
                            authorizationCode: authorizationCode
                        ) { result in
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
                                // 유저 정보 fetch
                                BackEndAuthService.shared
                                    .fetchMemberInfo(
                                        accessToken: tokenResponse.accessToken
                                    ) { result in
                                        switch result {
                                        case .success(let info):
                                            BackEndAuthService.shared.getUserCheckRate(
                                                accessToken: tokenResponse.accessToken
                                            ) { checkRate in
                                                let user = User(
                                                    id: info.memberId,
                                                    name: info.nickname,
                                                    friends: [],
                                                    checkRate: checkRate,
                                                    loginType: .apple,
                                                    serverAccessToken: tokenResponse.accessToken,
                                                    serverRefreshToken: tokenResponse.refreshTokenInfo.token
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
                                print("🔴 [UserSession] 서버 로그인 실패: \(error)")
                                self.logout()
                            }
                        }
                }
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
                    
                    BackEndAuthService.shared.getUserCheckRate(accessToken: accessToken) { checkRate in
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
                    // accessToken 만료라면 refreshToken으로 재발급 시도
                    if let refreshToken = TokenManager.shared.get(for: .server, isRefresh: true) {
                        print("🟡 [UserSession] accessToken 만료 → refreshToken으로 재발급 시도")
                        BackEndAuthService.shared.refreshAccessToken(refreshToken: refreshToken) { result in
                            switch result {
                            case .success(let newAccessToken):
                                print("🟢 [UserSession] 서버 accessToken 재발급 성공")
                                TokenManager.shared.save(token: newAccessToken, for: .server)
                                // 재시도
                                self.tryAutoLogin()
                            case .failure(let error):
                                print("🔴 [UserSession] 서버 토큰 재발급 실패: \(error.localizedDescription)")
                                self.logout()
                            }
                        }
                    } else {
                        self.logout()
                    }
                }
            }
            
            return
        }
        // 서버 accessToken이 없는 경우 - Apple 재로그인 후 서버 로그인
        print("🟡 [UserSession] 서버 accessToken 없음 → Apple 재로그인 시도")
        SnsAuthService.shared.tryAutoReLoginApple(presentationAnchor: window) { userId, identityToken, authorizationCode in
            guard let userId = userId,
                  let identityToken = identityToken,
                  let authorizationCode = authorizationCode else {
                self.logout()
                return
            }
            BackEndAuthService.shared.loginWithApple(userId: userId,
                                                     identityToken: identityToken,
                                                     authorizationCode: authorizationCode) { result in
                switch result {
                case .success(let tokenResponse):
                    TokenManager.shared.save(token: tokenResponse.accessToken, for: .server)
                    TokenManager.shared.save(token: tokenResponse.refreshTokenInfo.token,
                                             for: .server,
                                             isRefresh: true)
                    // 새 토큰으로 다시 자동 로그인 절차 진행
                    self.tryAutoLogin()
                case .failure(let error):
                    print("🔴 [UserSession] 서버 로그인 실패: \(error.localizedDescription)")
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
                
                //3. 예약된 / delivered된 알림들 삭제
                NotificationManager.shared.clearNotifications()

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

    
}
