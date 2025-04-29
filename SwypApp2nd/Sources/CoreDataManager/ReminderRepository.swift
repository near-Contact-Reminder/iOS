import CoreData
import UserNotifications

class ReminderRepository: ObservableObject {
    
    static let shared = ReminderRepository() // singleton
    private let context = CoreDataStack.shared.context

    func addReminder(person: Friend, reminderId: UUID, type: NotificationType, scheduledDate: Date) {
        let newReminder = ReminderEntity(context: context)
        newReminder.id = reminderId
        newReminder.date = scheduledDate
        newReminder.isRead = false
        newReminder.type = type.rawValue
        
        // MARK: - Person 연결
        let personID = person.id
        
        let fetchRequest: NSFetchRequest<PersonEntity> = PersonEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", personID as CVarArg)
        
        do {
            if let personEntity = try context.fetch(fetchRequest).first {
                // 독립적으로 entity / friend 생각하되, id가 맞는지 확인?
                personEntity.addToReminders(newReminder)
                newReminder.person = personEntity
            
            } else {
                let personEntity = PersonEntity.init(context: context, from: person)
              // Person entity 새로 만든 후 reminder entity랑 연결
                newReminder.person = personEntity
            }
        } catch {
            print("❌ PersonEntity fetch 실패: \(error.localizedDescription)")
            return
        }
    
        // 알림 브로드캐스트
        NotificationCenter.default.post(
            name: NSNotification.Name("NewReminderAdded"),
            object: nil,
            userInfo: [
                "personID": newReminder.person.id.uuidString,
                "reminderID": newReminder.id.uuidString,
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
    func fetchReminders(person: Friend) -> [ReminderEntity] {
        
        // friend.id -> personEntity id 를 찾아서 -> reminderEntity 를 리턴
        let personID = person.id.uuidString
        let request: NSFetchRequest<PersonEntity> = PersonEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", personID)

        do {
                if let personEntity = try context.fetch(request).first,
                   let remindersSet = personEntity.reminders as? Set<ReminderEntity> {
                    return Array(remindersSet)
                } else {
                    return []
                }
            } catch {
                print("❌ \(person.name)의 reminder 가져오기 실패: \(error.localizedDescription)")
                return []
            }
       }
    
    // 모든 Reminder 가져오기
    func fetchAllReminders() -> [ReminderEntity] {
        let request: NSFetchRequest<ReminderEntity> = ReminderEntity.fetchRequest()

        do {
            return try context.fetch(request)
        } catch {
            print("모든 Reminder 가져오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    // userInfo.personID == friend.id -> 이거 어떻게 비교?
    func fetchPerson(from userInfo: [AnyHashable: Any]) -> Friend? {
        guard let personID = userInfo["personID"] as? String,
              let uuid = UUID(uuidString: personID) else {
            print("❌ UserInfo에서 personID 가져오기 실패")
            return nil
        }
        
        return UserSession.shared.user?.friends.filter({$0.id.uuidString.lowercased() == personID.lowercased()}).first
    }
    
    func markAsRead(_ reminder: ReminderEntity) {
        reminder.isRead = true
        saveContext()
    }

    func markAsTriggered(_ reminder: ReminderEntity) {
        reminder.isTriggered = true
        saveContext()
    }
        
    private func saveContext() {
        CoreDataStack.shared.saveContext()
    }
}
