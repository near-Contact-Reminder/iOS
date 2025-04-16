import CoreData

class PersonRepository {
    private let context = CoreDataStack.shared.context

    func addPerson(name: String) -> PersonEntity {
        let newPerson = PersonEntity(context: context)
        newPerson.id = UUID()
        newPerson.name = name

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
