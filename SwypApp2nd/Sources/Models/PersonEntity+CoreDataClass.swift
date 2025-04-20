import Foundation
import CoreData

@objc(PersonEntity)
public class PersonEntity: NSManagedObject {
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
//    @NSManaged public var imageURL: String?
//    @NSManaged public var phoneNumber: String?
//    @NSManaged public var relationship: String?
//    @NSManaged public var birthDay: Date?
//    @NSManaged public var anniversaryTitle: String?
//    @NSManaged public var anniversaryDate: Date?
//    @NSManaged public var memo: String?
//    @NSManaged public var nextContactAt: Date?
//    @NSManaged public var lastContactAt: Date?
    @NSManaged public var reminderInterval: String?
//    @NSManaged public var position: Int
}
