import CoreData

class CoreDataStack {
    
    static let shared = CoreDataStack() // singleton
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NotificationContainer");
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ CoreData 로드 실패: \(error)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func clearAllData() {
        let entities = ["PersonEntity", "ReminderEntity"]

        for entityName in entities {
            let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            do {
                try context.execute(deleteRequest)
                print("🟢 [CoreDataStack] \(entityName) 삭제 완료")
            } catch {
                print("🔴 [CoreDataStack] \(entityName) 삭제 실패: \(error)")
            }
        }

        try? context.save()
        print("🟢 [CoreDataStack] 모든 Core Data 삭제 완료")
    }

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ CoreData 저장 성공")
            } catch {
                print("❌ CoreData 저장 실패: \(error.localizedDescription)")
            }
        }
    }
}
