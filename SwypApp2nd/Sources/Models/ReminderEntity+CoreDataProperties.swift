import Foundation
import CoreData


extension ReminderEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReminderEntity> {
        return NSFetchRequest<ReminderEntity>(entityName: "ReminderEntity")
    }
}

extension ReminderEntity {
    var notificationType: NotificationType {
        NotificationType(rawValue: self.type) ?? .regular
    }
}

extension ReminderEntity : Identifiable {

}
