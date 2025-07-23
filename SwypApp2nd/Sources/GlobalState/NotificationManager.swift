import Foundation
import SwiftUI
import FirebaseMessaging
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate, MessagingDelegate {

    static let shared = NotificationManager()
    let center = UNUserNotificationCenter.current()
    @ObservedObject var notificationViewModel: NotificationViewModel

    // FCM 토큰 저장 키
    private let fcmTokenKey = "FCMToken"

    init(viewModel: NotificationViewModel = NotificationViewModel()) {
        self.notificationViewModel = viewModel
        super.init()
        center.delegate = self
        Messaging.messaging().delegate = self
    }

    // MARK: - FCM 토큰 관리

    /// FCM 토큰을 UserDefaults에 저장
    func saveFCMToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: fcmTokenKey)
        print("📱 FCM 토큰 저장됨: \(token)")
        print("🔑 현재 FCM 토큰 (Firebase Console 테스트용): \(token)")
    }

    /// 저장된 FCM 토큰 가져오기
    func getFCMToken() -> String? {
        return UserDefaults.standard.string(forKey: fcmTokenKey)
    }

    /// FCM 토큰을 서버에 등록
    func registerFCMTokenToServer() {
        guard let token = getFCMToken(),
              let accessToken = TokenManager.shared.get(for: .server) else {
            print("⚠️ FCM 토큰 또는 서버 토큰이 없음")
            return
        }

        // 이미 등록된 토큰인지 확인
        let lastRegisteredToken = UserDefaults.standard.string(forKey: "LastRegisteredFCMToken")
        if lastRegisteredToken == token {
            print("📱 FCM 토큰이 이미 등록됨: \(token.prefix(20))...")
            return
        }

        // 서버에 FCM 토큰 등록
        BackEndAuthService.shared.registerFCMToken(token: token, accessToken: accessToken) { result in
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

    // MARK: - MessagingDelegate

    /// FCM 토큰이 갱신될 때 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            print("❌ FCM 토큰이 nil")
            return
        }

        saveFCMToken(token)

        // 로그인 상태일 때만 서버에 토큰 등록
        if TokenManager.shared.get(for: .server) != nil {
            registerFCMTokenToServer()
        } else {
            print("📱 로그인 상태가 아니므로 FCM 토큰 등록 보류")
            // TODO: 로그인 시도 해야 하나?
        }
    }

    // MARK: - APNS 토큰 설정
    /// APNS 토큰을 FCM에 설정
    func setAPNSToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("📱 APNS 토큰 설정됨: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")

        // APNS 토큰 설정 후 FCM 토큰 가져오기 시도
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refreshFCMToken()
        }
    }

    // MARK: - 권한 요청

    /// 최초 1회 권한 요청
    func requestPermissionIfNeeded() {
        let key = "didRequestNotificationPermission"
        guard !UserDefaults.standard.bool(forKey: key) else {
            // 이미 권한을 요청했다면 FCM 토큰 가져오기 시도
            self.refreshFCMToken()
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

    // MARK: - APNS 토큰 처리
    /// APNS 토큰을 받았을 때 호출
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        setAPNSToken(deviceToken)
    }

    /// APNS 등록 실패 시 호출
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNS 등록 실패: \(error)")
    }

    // MARK: - 푸시 알림 처리

    /// 앱이 포그라운드 상태에서 푸시를 받을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let userInfo = notification.request.content.userInfo
        print("📱 포그라운드에서 푸시 수신: \(userInfo)")

        // FCM 메시지 처리
        handleFCMNotification(userInfo: userInfo)

        completionHandler([.list, .banner, .sound, .badge])
    }

    /// 사용자가 푸시를 클릭했을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 유저가 알림을 클릭함")
        let userInfo = response.notification.request.content.userInfo

        // FCM 메시지 처리
        handleFCMNotification(userInfo: userInfo)

        // auto login check -> app step 쌓는 과정
        notificationViewModel.navigateFromNotification(userInfo: userInfo)
#if !DEBUG
        AnalyticsManager.shared.setEntryChannel("push")
#endif
        completionHandler()
    }

    /// FCM 알림 데이터 처리
    // TODO 데이터 구조 확인 후 수정 필요
    private func handleFCMNotification(userInfo: [AnyHashable: Any]) {
        print("📱 FCM 메시지 수신: \(userInfo)")

        // FCM 메시지 구조 파싱 (다양한 형태 지원)
        var title = ""
        var body = ""

        // 1. 표준 FCM 구조 (aps.alert)
        if let aps = userInfo["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any] {
            title = alert["title"] as? String ?? ""
            body = alert["body"] as? String ?? ""
        }
        // 2. 단순 문자열 형태 (aps.alert)
        else if let aps = userInfo["aps"] as? [String: Any],
                let alert = aps["alert"] as? String {
            body = alert
        }
        // 3. 커스텀 데이터에서 직접 추출
        else {
            title = userInfo["title"] as? String ?? ""
            body = userInfo["body"] as? String ?? ""
            friendId = userInfo["friendId"] as? String ?? ""
        }

        print("📱 FCM 메시지 처리 - 제목: \(title), 내용: \(body)")

        // 로컬 알림에 추가 (최소 정보만)
        // handleFCMNotification에서 addLocalNotification은 NotificationViewModel.shared.addLocalNotification(...)으로 대체 필요 (싱글턴/DI 구조에 맞게 조정)
        notificationViewModel.addLocalNotification(
            friendId: friendId,
            friendName: "",
            title: title.isEmpty ? "알림" : title,
            body: body,
            isRead: false
        )

        print("📱 FCM 알림 처리 완료 - 로컬 알림 추가됨")
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
        center.removeAllPendingNotificationRequests() // TODO remove 가 아니라 pause 처리 필요
        print("⏸️ FCM 알림 일시정지됨")
    }

    /// 알림 재개
    func resumeNotifications() {
        // FCM 알림 재개 상태로 설정
        UserDefaults.standard.set(false, forKey: "notificationsPaused")

        // FCM 토큰을 다시 서버에 등록
        if TokenManager.shared.get(for: .server) != nil {
            registerFCMTokenToServer()
        }

        print("▶️ FCM 알림 재개됨")
    }

    /// 로컬 알림 정리
    func clearNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    /// FCM 토큰 갱신
    func refreshFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ FCM 토큰 갱신 실패: \(error)")
                return
            }

            if let token = token {
                self.saveFCMToken(token)

                // 로그인 상태일 때만 서버에 등록
                if TokenManager.shared.get(for: .server) != nil {
                    self.registerFCMTokenToServer()
                }
            }
        }
    }

    /// FCM 토큰 상태 확인
    func getFCMTokenStatus() -> (token: String?, isRegistered: Bool) {
        let token = getFCMToken()
        let lastRegisteredToken = UserDefaults.standard.string(forKey: "LastRegisteredFCMToken")
        let isRegistered = token == lastRegisteredToken && token != nil

        return (token, isRegistered)
    }
}
