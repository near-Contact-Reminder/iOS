//
//  ReminderEntity+CoreDataProperties.swift
//  SwypApp2nd
//
//  Created by Sharon Kang on 3/29/25.
//
//

import Foundation
import CoreData


extension ReminderEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReminderEntity> {
        return NSFetchRequest<ReminderEntity>(entityName: "ReminderEntity")
    }
}

extension ReminderEntity : Identifiable {

}
