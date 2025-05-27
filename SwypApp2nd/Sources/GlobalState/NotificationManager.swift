import Foundation
import CoreData
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    let center = UNUserNotificationCenter.current()
    private let reminderRepo = ReminderRepository()
    @ObservedObject var notificationViewModel: NotificationViewModel
    
    init(viewModel: NotificationViewModel = NotificationViewModel()) {
        self.notificationViewModel = viewModel
        super.init()
        center.delegate = self
    }
    
    // MARK: - 최초 1회 권한 요청
    func requestPermissionIfNeeded() {
        let key = "didRequestNotificationPermission"
        
        // 이미 권한 요청 완료
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        
        // 최초 한 번만 실행
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if error == nil {
                DispatchQueue.main.async {
                    UserDefaults.standard.set(true, forKey: key)
                }
            }
        }
    }
    
    /// 푸시 받을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    
        let userInfo = notification.request.content.userInfo

        if let reminderIdString = userInfo["reminderID"] as? String,
          let reminderId = UUID(uuidString: reminderIdString) {
           notificationViewModel.isTriggered(reminderId: reminderId)
       }

        completionHandler([.list, .banner, .sound, .badge])
    }
    
    // MARK: - 사용자가 푸시를 클릭했을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 유저가 알림을 클릭함")
        let userInfo = response.notification.request.content.userInfo
        // auto login check -> app step 쌓는 과정
        notificationViewModel.navigateFromNotification(userInfo: userInfo)  // CoreData 저장
        AnalyticsManager.shared.setEntryChannel("push")
        completionHandler()
    }
    
    // MARK: - 현재 권한 상태 확인
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // MARK: - 알림 비활성화
    func disableNotifications() {
        center.removeAllPendingNotificationRequests()
        UserDefaults.standard.set(true, forKey: "didManuallyDisableNotification")
        print("🚫 알림 비활성화됨")
    }
}
    
