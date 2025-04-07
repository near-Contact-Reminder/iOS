import Foundation
import CoreData

@objc(PersonEntity)
public class PersonEntity: NSManagedObject {
    
    @NSManaged public var id: UUID
    @NSManaged var name: String
    @NSManaged var birthday: Date?
    @NSManaged var anniversary: Date?
    @NSManaged var relationship: String
    @NSManaged var reminderInterval: String  
    @NSManaged var reminders: NSSet?
    @NSManaged var memo: String?
    

}
