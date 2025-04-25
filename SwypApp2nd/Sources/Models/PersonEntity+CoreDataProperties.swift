import Foundation
import CoreData


extension PersonEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersonEntity> {
        return NSFetchRequest<PersonEntity>(entityName: "PersonEntity")
    }
}

extension PersonEntity {
    convenience init(context: NSManagedObjectContext, from friend: Friend) {
        self.init(context: context)
        self.id = friend.id
        self.name = friend.name
    }
}

// MARK: Generated accessors for reminders
extension PersonEntity {

    @objc(addRemindersObject:)
    @NSManaged public func addToReminders(_ value: ReminderEntity)

    @objc(removeRemindersObject:)
    @NSManaged public func removeFromReminders(_ value: ReminderEntity)

    @objc(addReminders:)
    @NSManaged public func addToReminders(_ values: NSSet)

    @objc(removeReminders:)
    @NSManaged public func removeFromReminders(_ values: NSSet)

}

extension PersonEntity : Identifiable {

}
