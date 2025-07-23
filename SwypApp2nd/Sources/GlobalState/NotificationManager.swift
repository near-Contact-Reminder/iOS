import Foundation
import SwiftUI
import FirebaseMessaging
import UserNotifications
import FirebaseMessaging
import UserNotifications

// NotificationManager → FCM 토큰, 알림 권한, FCM 메시지 처리
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate, MessagingDelegate {

    static let shared = NotificationManager()
    let center = UNUserNotificationCenter.current()
    @Published var navigateToPerson: Friend?
    let inboxViewModel: InboxViewModel = InboxViewModel()
    private let fcmTokenKey = "FCMToken"

    override init() {
        super.init()
        center.delegate = self
        Messaging.messaging().delegate = self
    }

    /// FCM 토큰을 UserDefaults에 저장
    func setFCMToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: fcmTokenKey)
        print("🟢 [NotificationManager] FCM 토큰 저장: \(token)")
    }

    /// 저장된 FCM 토큰 가져오기
    func getFCMToken() -> String? {
        return UserDefaults.standard.string(forKey: fcmTokenKey)
    }

    /// FCM 토큰 갱신
    func refreshFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ FCM 토큰 갱신 실패: \(error)")
                return
            }

            if let token = token {
                self.setFCMToken(token)

                // 로그인 상태일 때만 서버에 등록
                if TokenManager.shared.get(for: .server) != nil {
                    self.registerFCMToken()
                }
            }
        }
    }

    /// FCM 토큰을 서버에 등록
    func registerFCMToken() {

        guard let token = getFCMToken() else {
            print("❌ [NotificationManager] FCM 토큰이 없음")
            return
        }

        guard let accessToken = TokenManager.shared.get(for: .server) else {
            print("❌ [NotificationManager] 서버 액세스 토큰이 없음")
            return
        }

        // 이미 등록된 토큰인지 확인
        let lastRegisteredToken = UserDefaults.standard.string(forKey: "LastRegisteredFCMToken")
        if lastRegisteredToken == token {
            print("📱 FCM 토큰이 이미 등록됨: \(token.prefix(20))...")
            return
        }

        // 서버에 FCM 토큰 등록
        BackEndAuthService.shared.registerFCMTokenToServer(token: token, accessToken: accessToken) { result in
            switch result {
            case .success:
                print("✅ FCM 토큰 서버 등록 성공")
                // 등록 성공 시 마지막 등록 토큰 저장
                UserDefaults.standard.set(token, forKey: "LastRegisteredFCMToken")
            case .failure(let error):
                print("❌ FCM 토큰 서버 등록 실패: \(error)")
            }
        }
    }

    func unregisterFCMToken() {

        // 1. 로컬 알림 정리
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // 4. InboxViewModel 데이터 정리
        inboxViewModel.clearAllNotifications()

        // 1. 서버에서 FCM 토큰 삭제
        if let accessToken = TokenManager.shared.get(for: .server), 
           let token = getFCMToken() {
            BackEndAuthService.shared.unregisterFCMToken(
                token: token,
                accessToken: accessToken
            ) { result in
                switch result {
                case .success:
                    print("🟢 [NotificationManager] 서버 FCM 토큰 삭제 성공")
                case .failure(let error):
                    print("🔴 [NotificationManager] 서버 FCM 토큰 삭제 실패: \(error)")
                }
            }
        }

        // 2. 클라이언트에서 FCM 토큰 삭제
        Messaging.messaging().deleteToken { error in
            if let error = error {
                print("🔴 [NotificationManager] 클라이언트 FCM 토큰 삭제 실패: \(error)")
            } else {
                print("🟢 [NotificationManager] 클라이언트 FCM 토큰 삭제 성공")
            }
        }
}

    /// FCM 토큰이 갱신될 때 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            print("❌ FCM 토큰이 nil")
            return
        }

        setFCMToken(token)

        // 로그인 상태일 때만 서버에 토큰 등록
        if TokenManager.shared.get(for: .server) != nil {
            registerFCMToken()
        } else {
            print("📱 로그인 상태가 아니므로 FCM 토큰 등록 보류")
            // TODO: 로그인 시도 해야 하나?
        }
    }

    /// APNS 토큰을 FCM에 설정
    func setAPNSToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("📱 APNS 토큰 설정됨: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")

        // APNS 토큰 설정 후 FCM 토큰 가져오기 시도
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refreshFCMToken()
        }
    }

    /// 최초 1회 권한 요청
    func requestPermissionIfNeeded() {
        let key = "didRequestNotificationPermission"
        guard !UserDefaults.standard.bool(forKey: key) else {
            // 이미 권한을 요청했다면 APNS 토큰이 설정되었는지 확인
            if Messaging.messaging().apnsToken != nil {
                self.refreshFCMToken()
            } else {
                print("🟡 [NotificationManager] 권한 이미 요청됨, APNS 토큰 대기 중...")
            }
            return
        }

        // 최초 한 번만 실행
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: key)
                if granted {
                    print("✅ 알림 권한 승인됨")
                    // 권한이 승인된 후 FCM 토큰 가져오기
                    self.refreshFCMToken()
                } else {
                    print("❌ 알림 권한 거부됨")
                }
            }
        }
    }

    /// APNS 토큰을 받았을 때 호출
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        setAPNSToken(deviceToken)
    }

    /// APNS 등록 실패 시 호출
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNS 등록 실패: \(error)")
    }

    /// 앱이 포그라운드 상태에서 푸시를 받을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let userInfo = notification.request.content.userInfo
        print("📱 포그라운드에서 푸시 수신: \(userInfo)")

        // FCM 메시지 처리
        generateLocalNotification(userInfo: userInfo)
        completionHandler([.list, .banner, .sound, .badge])
    }

    /// 사용자가 푸시를 클릭했을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 유저가 알림을 클릭함")
        let userInfo = response.notification.request.content.userInfo
        // auto login check -> app step 쌓는 과정
         guard let friendId = userInfo["friendId"] as? UUID else {
            print("🔴 [NotificationManager] friendId 파싱 실패")
            return
        }
        navigateFromNotification(friendId: friendId)
#if !DEBUG
        AnalyticsManager.shared.setEntryChannel("push")
#endif
        completionHandler()
    }

    /// FCM 알림 데이터 처리
    private func generateLocalNotification(userInfo: [AnyHashable: Any]) {
        print("📱 FCM 메시지 수신: \(userInfo)")

        // 1. friendId 파싱 (String → UUID)
        guard let friendIdString = userInfo["friendId"] as? String,
            let friendId = UUID(uuidString: friendIdString) else {
            print("🔴 [NotificationManager] FCM payload에서 friendId 파싱 실패")
            return
        }

        // 2. body 파싱
        let body = userInfo["body"] as? String ?? "새로운 알림이 있습니다"

        let notificationDate = userInfo["date"] as? Date ?? Date()

        // 3. LocalNotificationModel 생성
        let notification = LocalNotificationModel(
            friendId: friendId,
            body: body,
            date: notificationDate,
            isRead: false
        )
            inboxViewModel.addNotification(notification)
        }

    // MARK: - 현재 권한 상태 확인
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    /// 알림 비활성화
    func disableNotifications() {
        // 서버에 FCM 토큰 해제 요청
        guard let token = getFCMToken(),
              let accessToken = TokenManager.shared.get(for: .server) else {
            print("⚠️ FCM 토큰 또는 서버 토큰이 없음 (unregister 생략)")
            return
        }

        BackEndAuthService.shared.unregisterFCMToken(token: token, accessToken: accessToken) { result in
            switch result {
            case .success:
                print("✅ 서버에 FCM 토큰 해제 성공")
                // 로컬 FCM 토큰 삭제
                Messaging.messaging().deleteToken { error in
                    if let error = error {
                        print("❌ FCM 토큰 삭제 실패: \(error)")
                    } else {
                        print("✅ FCM 토큰 삭제 성공")
                    }
                }
                // 로컬 저장된 토큰도 삭제
                UserDefaults.standard.removeObject(forKey: self.fcmTokenKey)
                UserDefaults.standard.set(true, forKey: "didManuallyDisableNotification")
                print("🚫 FCM 알림 비활성화됨")
            case .failure(let error):
                print("❌ 서버에 FCM 토큰 해제 실패: \(error)")
            }
        }
    }

    /// 알림 일시정지
    func pauseNotifications() {
        // FCM 알림 일시정지 상태로 설정
        UserDefaults.standard.set(true, forKey: "notificationsPaused")
        self.disableNotifications()
        print("⏸️ FCM 알림 일시정지됨")
    }

    /// 알림 재개
    func resumeNotifications() {
        // FCM 알림 재개 상태로 설정
        UserDefaults.standard.set(false, forKey: "notificationsPaused")

        // FCM 토큰을 다시 서버에 등록
        if TokenManager.shared.get(for: .server) != nil {
            registerFCMToken()
        }

        print("▶️ FCM 알림 재개됨")
    }

    private func navigateFromNotification(friendId: UUID) {
        inboxViewModel.navigateToFriend(friendId: friendId)
    }
}
