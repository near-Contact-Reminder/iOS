import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var lastResponse: UNNotificationResponse?
    let notificationViewModel = NotificationViewModel()

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // Foreground에서 푸시 받을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // 사용자가 푸시를 클릭했을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 유저가 알림을 클릭함")
        lastResponse = response  // 필요 시 바인딩으로 뷰에 전달 가능
        notificationViewModel.handleNotification(response)  // CoreData 저장
        completionHandler()
    }
}
