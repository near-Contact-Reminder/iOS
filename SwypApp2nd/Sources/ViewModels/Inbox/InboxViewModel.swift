import SwiftUI
import Combine

// InboxViewModel → 알림 목록, 뱃지 관리, UI 상태 관리
class InboxViewModel: ObservableObject {

    @Published var notifications: [LocalNotificationModel] = []
    @Published var navigateToPerson: Friend?
    @Published var badgeCount: Int = 0
    @Published var showBadge: Bool = false

    func addNotification(_ notification: LocalNotificationModel) {
        DispatchQueue.main.async {
            self.notifications.append(notification)
            self.updateBadgeCount()
        }
    }

    func deleteNotification(_ notification: LocalNotificationModel) {
        DispatchQueue.main.async {
            self.notifications.removeAll { $0.id == notification.id }
            self.updateBadgeCount()
        }
    }

    func clearAllNotifications() {
        DispatchQueue.main.async {
            self.notifications.removeAll()
            self.updateBadgeCount()
        }
    }

    func updateBadgeCount() {
        let unreadCount = notifications.filter { !$0.isRead }.count
        UNUserNotificationCenter.current().setBadgeCount(unreadCount)
        if unreadCount > 0 {
            showBadge = true
        } else {
            showBadge = false
        }
    }

    func navigateToFriend(friendId: UUID) {
        let currentFriend = UserSession.shared.user!.friends.first { $0.id == friendId }
        DispatchQueue.main.async {
            self.navigateToPerson = currentFriend
        }
    }

    func loadNotifications() {
        // 알림 목록을 로드하는 로직 (현재는 빈 배열로 초기화)
        // 실제로는 서버에서 데이터를 가져오거나 로컬 저장소에서 로드
        DispatchQueue.main.async {
            self.updateBadgeCount()
        }
    }

    func handleNotificationTap(_ notification: LocalNotificationModel) {
        // 알림을 읽음 상태로 변경
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            DispatchQueue.main.async {
                self.notifications[index].isRead = true
                self.updateBadgeCount()
            }
        }

        // 해당 친구로 네비게이션
        navigateToFriend(friendId: notification.friendId)

        // 네비게이션 후 navigateToPerson 초기화 (중복 네비게이션 방지)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.navigateToPerson = nil
        }
    }

}
