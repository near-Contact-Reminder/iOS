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
        person.relationship = "친구"
        person.reminderInterval = "2주"
        person.birthday = Calendar.current.date(from: DateComponents(year: 1996, month: 3, day: 21))
        person.anniversary = Calendar.current.date(from: DateComponents(year: 2020, month: 6, day: 24))
        person.memo = "초밥 안 먹는 친구"
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

extension PersonEntity : Identifiable {

}
