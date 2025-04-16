enum NotificationType: String {
    case regular
    case birthday
    case anniversary
    case unknown
}

struct ReminderRequest: Encodable {
    let personId: String
    let name: String
    let type: String // "regular", "birthday", etc.
    let scheduledAt: String // ISO8601 date string
}
