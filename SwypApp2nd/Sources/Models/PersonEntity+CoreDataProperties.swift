//
//  PersonEntity+CoreDataProperties.swift
//  SwypApp2nd
//
//  Created by Sharon Kang on 3/29/25.
//
//

import Foundation
import CoreData


extension PersonEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersonEntity> {
        return NSFetchRequest<PersonEntity>(entityName: "PersonEntity")
    }
    
    static func mockPerson(context: NSManagedObjectContext) -> PersonEntity {
        let person = PersonEntity(context: context)
        person.name = "강다연"
        return person
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

extension PersonEntity {
    func toFriend() -> Friend {
        return Friend(
            id: self.id,
            name: self.name,
            image: nil,
            imageURL: self.imageURL,
            source: .phone, // or .kakao
            frequency: CheckInFrequency(rawValue: self.reminderInterval ?? ""),
            remindCategory: nil,
            phoneNumber: self.phoneNumber,
            relationship: self.relationship,
            birthDay: self.birthDay,
            anniversary: AnniversaryModel(
                title: self.anniversaryTitle,
                Date: self.anniversaryDate
            ),
            memo: self.memo,
            nextContactAt: self.nextContactAt,
            lastContactAt: self.lastContactAt,
            checkRate: nil,
            position: Int(self.position)
        )
    }
}


extension PersonEntity : Identifiable {

}
