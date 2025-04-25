import SwiftUI
import CoreData

class ProfileEditViewModel: ObservableObject {
    @Published var person: Friend
    @Published var people: [PersonEntity] = []
    
    init(person: Friend, people: [PersonEntity] = []) {
        self.person = person
        self.people = people
    }
}
