import CoreData

class ReminderRepository {
    private let context = CoreDataStack.shared.context

    func addReminder(person: Friend, type: NotificationType, scheduledDate: Date) {
        let newReminder = ReminderEntity(context: context)
        newReminder.id = person.id
        newReminder.date = scheduledDate
        newReminder.isRead = false
        print(type.rawValue)
        newReminder.type = type.rawValue
        
        // MARK: - Person 연결
        var entity: PersonEntity?
        
        if let existingEntity = person.entity {
               entity = existingEntity
        } else {
            // CoreData에서 찾아보기
            let personID = person.entity?.id ?? person.id
            
            let fetchRequest: NSFetchRequest<PersonEntity> = PersonEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", personID as CVarArg)
            
            do {
                if let found = try context.fetch(fetchRequest).first {
                    entity = found
                } else {
                        entity = person.toPersonEntity(context: context) // 새로 생성
                    }
                } catch {
                    print("❌ PersonEntity fetch 실패: \(error.localizedDescription)")
                    return
                    }
                }
        
        
        guard let personEntity = entity else {
                print("❌ PersonEntity 설정 실패")
                return
            }

        newReminder.person = personEntity


        // 알림 브로드캐스트
        NotificationCenter.default.post(
            name: NSNotification.Name("NewReminderAdded"),
            object: nil,
            userInfo: [
                "personID": personEntity.id.uuidString,
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
    
    func fetchPerson(from userInfo: [AnyHashable: Any]) -> Friend? {
       guard let personID = userInfo["personID"] as? String,
                let uuid = UUID(uuidString: personID) else {
           print("❌ UserInfo에서 personID 가져오기 실패")
           return nil
       }
       
       let fetchRequest: NSFetchRequest<PersonEntity> = PersonEntity.fetchRequest()
       fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)

        do {
            if let entity = try context.fetch(fetchRequest).first {
                return Friend(from: entity) 
            } else {
                print("[reminder repo] ❌ entity 연결 Friend 찾기 실패")
                return nil
            }
        } catch {
            print("[reminder repo] ❌ PersonEntity 찾기 실패: \(error.localizedDescription)")
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
