import SwiftUI
import UserNotifications
import CoreData

class ProfileEditViewModel: ObservableObject {
    @Published var person: Friend
    
    private let personRepo = PersonRepository()
    private let reminderRepo = ReminderRepository()
    
    @Published var people: [PersonEntity] = []
//    @Published var reminders: [ReminderEntity] = []
    
    init(person: Friend, people: [PersonEntity] = []) {
        self.person = person
        self.people = people
    }
    
    func addNewPerson(name: String,reminderInterval: String) {
        let newPerson = personRepo.addPerson(name: name, reminderInterval: reminderInterval)
        //entity id -> friend.id -> friend.type return
//        reminderRepo.addReminder(person: newPerson, type: friend.type ., )
    }
    
}
