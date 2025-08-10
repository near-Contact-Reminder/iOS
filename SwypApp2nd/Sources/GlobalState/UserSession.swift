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
    
    /// 마이그레이션 상태 확인 및 실행
    private func checkMigrationStatus() {
        // accessToken 체크
        guard let accessToken = TokenManager.shared.get(for: .server) else {
            print("🔴 [UserSession] 마이그레이션 실패 - 서버 액세스 토큰이 없음")
            return
        }

        // 이미 마이그레이션 완료되었는지 확인
        if UserDefaults.standard.object(forKey: "isMigrated") == nil {
            print("🟢 [UserSession] 마이그레이션 불필요 - 신규 유저")
            UserDefaults.standard.set(true, forKey: "isMigrated")
            return
        }

        let migrationStatus = UserDefaults.standard.object(forKey: "isMigrated") as? Bool
        if migrationStatus == false {
            // 기존 친구 목록 가져오기
            if let friends = self.user?.friends, !friends.isEmpty {
                print("🟡 [UserSession] 기존 친구 \(friends.count)명 마이그레이션 시작")
                
                // friend/init API 호출로 마이그레이션 실행
                BackEndAuthService.shared.sendInitialFriends(friends: friends, accessToken: accessToken) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let friendsWithURLs):
                            print("🟢 [UserSession] 마이그레이션 성공: \(friendsWithURLs.count)명")
                            UserDefaults.standard.set(true, forKey: "isMigrated")
                            CoreDataStack.shared.clearAllData()
                            
                        case .failure(let error):
                            print("🔴 [UserSession] 마이그레이션 실패: \(error)")
                            UserDefaults.standard.set(false, forKey: "isMigrated")
                        }
                    }
                }
            } else {
                print("🟡 [UserSession] 기존 친구가 없음 - 마이그레이션 불필요")
                UserDefaults.standard.set(true, forKey: "isMigrated")
            }
        } else {
            print("🟢 [UserSession] 이미 마이그레이션 완료됨")
        }
    }

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

            // 로그인 완료 후 마이그레이션 실행
            print("🟡 [UserSession] updateUser - 0.5초 후 마이그레이션 실행 예정")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("🟢 [UserSession] 마이그레이션 실행 시작")
                self.checkMigrationStatus()
            }
        }
    }

    /// 로그아웃 처리
    func logout() {
        // FCM 알림 일시정지
        NotificationManager.shared.pauseNotifications()
        
        // FCM 토큰 관련 정리
        UserDefaults.standard.removeObject(forKey: "LastRegisteredFCMToken")
        
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
                                            self.getUserCheckRate(
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
                                                                self.getUserCheckRate(
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
                                            self.getUserCheckRate(
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
