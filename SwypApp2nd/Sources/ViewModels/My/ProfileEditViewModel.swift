import SwiftUI
import UserNotifications
import CoreData

class ProfileEditViewModel: ObservableObject {
    
    private let personRepo = PersonRepository()
    private let reminderRepo = ReminderRepository()
    
    @Published var people: [PersonEntity] = []
    @Published var reminders: [ReminderEntity] = []
    
    func addNewPerson(name: String, relationship: String, birthday: Date?, anniversary: Date?, reminderInterval: String, memo: String?) {
//        let newPerson = personRepo.addPerson(name: name, relationship: relationship, birthday: birthday, anniversary: anniversary, reminderInterval: reminderInterval, memo:memo)
//        reminderRepo.addReminder(for: newPerson)
    }
    
}
