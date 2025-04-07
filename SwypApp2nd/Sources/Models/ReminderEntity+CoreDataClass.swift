//
//  ReminderEntity+CoreDataClass.swift
//  SwypApp2nd
//
//  Created by Sharon Kang on 3/29/25.
//
//

import Foundation
import CoreData

@objc(ReminderEntity)
public class ReminderEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged var date : Date // TODO 알림 받는 날짜..?
    @NSManaged var lastContact: Date? // TODO: 고도화 - end date 설정
    @NSManaged var isRead: Bool
    @NSManaged var person: PersonEntity?

}
