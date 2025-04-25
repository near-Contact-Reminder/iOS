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
    
    // 친구 상세 정보 업데이트 메소드
    func updateFriendDetail(friendId: UUID, completion: @escaping () -> Void) {
        
        guard let token = UserSession.shared.user?.serverAccessToken else { return }

        let dto = FriendUpdateRequestDTO(
            name: person.name,
//            relation: person.mappedRelation(from: person.relationship),
            relation: person.relationship,
            contactFrequency: {
                guard let freq = person.frequency,
                      let contactWeek = freq.toContactWeek()
                else { return nil }
                return ContactFrequencyDTO(contactWeek: contactWeek, dayOfWeek: person.nextContactAt?.dayOfWeekString() ?? "MONDAY")
            }(),
            birthday: person.birthDay?.formattedYYYYMMDD(),
            anniversaryList: {
                if let anniversary = person.anniversary {
                    return [FriendUpdateRequestAnniversaryDTO(id: anniversary.id, title: anniversary.title, date: anniversary.Date?.formattedYYYYMMDD())]
                } else {
                    return nil
                }
            }(),
            memo: person.memo,
            phone: person.phoneNumber
        )
        
        BackEndAuthService.shared.updateFriend(friendId: friendId, request: dto, accessToken: token) { result in
            switch result {
            case .success:
                print("🟢 [ProfileDetailViewModel] 친구 상세 정보 업데이트 성공")
                completion()
            case .failure(let error):
                print("🔴 [ProfileDetailViewModel] 친구 상세 정보 업데이트 실패: \(error)")
            }
        }
    }
}
