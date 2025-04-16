import CoreData
import UserNotifications

class ReminderRepository {
    private let context = CoreDataStack.shared.context

    func addReminder(for person: Friend, type: NotificationType, scheduledDate: Date) {
        let newReminder = ReminderEntity(context: context)
        newReminder.id = UUID()
        newReminder.date = scheduledDate // TODO 가장 최신 reminder date을 가져오는 로직
        newReminder.isRead = false
        newReminder.type = type.rawValue
        
        // MARK: - Person 연결
//        let personID = person.entity.id

//        let fetchRequest: NSFetchRequest<PersonEntity> = PersonEntity.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "id == %@", personID as CVarArg)
//
//        let entity: PersonEntity
//        if let existing = try? context.fetch(fetchRequest).first {
//            entity = existing
//        } else {
//            entity = person.toPersonEntity(context: context)
//        }
//        newReminder.person = entity

        // 알림 브로드캐스트
        NotificationCenter.default.post(
            name: NSNotification.Name("NewReminderAdded"),
            object: nil,
            userInfo: [
                "personID": "", // entity.id.uuidString,
                "type": type.rawValue
            ]
        )
        saveContext()
    }
    
    func deleteReminder(_ reminder: ReminderEntity) {
            context.delete(reminder)
            do {
                try context.save() // CoreData에서 삭제 반영
                print("✅ Reminder 삭제 성공")
            } catch {
                print("❌ Reminder 삭제 실패: \(error.localizedDescription)")
            }
        }

    // 특정 `PersonEntity`에 대한 Reminder 가져오기
    func fetchReminders(for person: PersonEntity) -> [ReminderEntity] {
        let request: NSFetchRequest<ReminderEntity> = ReminderEntity.fetchRequest()
        request.predicate = NSPredicate(format: "person == %@", person)
        request.sortDescriptors = [NSSortDescriptor(key: "Date", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ \(person.name)의 reminder 가져오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    // 모든 Reminder 가져오기
    func fetchAllReminders() -> [ReminderEntity] {
        let request: NSFetchRequest<ReminderEntity> = ReminderEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("모든 Reminder 가져오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchPerson(from userInfo: [AnyHashable: Any]) -> PersonEntity? {
       guard let personID = userInfo["personID"] as? String,
                let uuid = UUID(uuidString: personID) else {
           print("❌ UserInfo에서 personID 가져오기 실패")
           return nil
       }
       
       let fetchRequest: NSFetchRequest<PersonEntity> = PersonEntity.fetchRequest()
       fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)

       do {
           return try context.fetch(fetchRequest).first
       } catch {
           print("❌ PersonEntity 찾기 실패: \(error.localizedDescription)")
           return nil
       }
   }
    
    func markAsRead(_ reminder: ReminderEntity) {
        reminder.isRead = true
        saveContext()
    }

        
    private func saveContext() {
        CoreDataStack.shared.saveContext()
    }
}
