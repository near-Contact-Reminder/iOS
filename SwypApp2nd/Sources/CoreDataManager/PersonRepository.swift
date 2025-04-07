import CoreData

class PersonRepository {
    private let context = CoreDataStack.shared.context

    func addPerson(name: String, relationship: String, birthday: Date?, anniversary: Date?, reminderInterval: String, memo: String?) -> PersonEntity {
        let newPerson = PersonEntity(context: context)
        newPerson.id = UUID()
        newPerson.name = name
        newPerson.relationship = relationship
        newPerson.birthday = birthday
        newPerson.anniversary = anniversary
        newPerson.reminderInterval = reminderInterval // "매일", "매주", "2주", "매달", "매분기", "6개월", "매년"
        newPerson.memo = memo ?? ""

        saveContext()
        return newPerson
    }

    func fetchPeople() -> [PersonEntity] {
        let request: NSFetchRequest<PersonEntity> = PersonEntity.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("사람 목록 불러오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
        func deletePerson(_ person: PersonEntity) {
            context.delete(person)
            saveContext()
        }

    

    private func saveContext() {
        CoreDataStack.shared.saveContext()
    }
}
