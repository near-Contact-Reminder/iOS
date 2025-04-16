import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    let notificationViewModel = NotificationViewModel()
    let context = CoreDataStack.shared.context
    private let reminderRepo = ReminderRepository()
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - 최초 1회 권한 요청
    func requestPermissionIfNeeded() {
        let key = "didRequestNotificationPermission"
        
        // 이미 권한 요청 완료
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        
        // 최초 한 번만 실행
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if error == nil {
                DispatchQueue.main.async {
                    UserDefaults.standard.set(true, forKey: key)
                }
            }
        }
    }
    
    // MARK: - Foreground에서 푸시 받을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound, .badge])
    }
    
    // MARK: - 사용자가 푸시를 클릭했을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 유저가 알림을 클릭함")
        notificationViewModel.navigateFromNotification(response)  // CoreData 저장
        completionHandler()
    }
    
    // MARK: - 현재 권한 상태 확인
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // MARK: - 알림 비활성화
    func disableNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UserDefaults.standard.set(true, forKey: "didManuallyDisableNotification")
        print("🚫 알림 비활성화됨")
    }
}
    
extension NotificationManager {
    
//    // MARK: - 알림 등록
//    func scheduleReminders(for person: Friend) {
//        scheduleBirthdayAnniversaryReminder(for: person)
//    }
 
}
