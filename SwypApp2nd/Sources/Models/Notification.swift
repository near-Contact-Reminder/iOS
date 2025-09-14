import Foundation

struct LocalNotificationModel: Codable, Equatable, Hashable, Identifiable {
        var id: UUID
        var friendId: UUID
        var body: String
        var date: Date?
        var isRead: Bool

    init(friendId: UUID, body: String, date: Date = Date(), isRead: Bool = false) {
        self.id = UUID()
        self.friendId = friendId
        self.body = body
        self.date = date
        self.isRead = isRead
    }
}

enum NotificationType: String, Codable {
    case regular
    case birthday
    case anniversary
    case unknown
}
