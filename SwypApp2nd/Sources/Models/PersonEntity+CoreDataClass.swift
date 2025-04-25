import Foundation
import CoreData

@objc(PersonEntity)
public class PersonEntity: NSManagedObject {
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
}
