import Foundation
import CoreData

@objc(ReminderEntity)
public class ReminderEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged var date : Date // TODO 알림 받는 날짜..?
    @NSManaged var isRead: Bool
    @NSManaged var person: PersonEntity
    @NSManaged var type: String
    @NSManaged var isTriggered: Bool
}
