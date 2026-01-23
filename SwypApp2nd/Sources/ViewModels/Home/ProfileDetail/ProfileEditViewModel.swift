import SwiftUI
import UserNotifications
import CoreData

class ProfileEditViewModel: ObservableObject {
    @Published var person: Friend
    
    struct ValidationErrors {
        var nameError: String?
        var anniversaryError: String?
        
        var hasError: Bool {
            nameError != nil || anniversaryError != nil
        }
    }
    
//    private let personRepo = PersonRepository()
    private let reminderRepo = ReminderRepository()
    
    @Published var people: [PersonEntity] = []
//    @Published var reminders: [ReminderEntity] = []
    
    init(person: Friend, people: [PersonEntity] = []) {
        self.person = person
        self.people = people
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

    /// 입력값 검증: 이름 필수, 기념일 제목/날짜 모두 필요
    func validateInputs() -> ValidationErrors? {
        var errors = ValidationErrors()
        
        let trimmedName = person.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            errors.nameError = "이름을 입력해주세요."
        }

        let anniversary = person.anniversary
        let title = anniversary?.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let date = anniversary?.Date
        if anniversary == nil || title.isEmpty || date == nil {
            errors.anniversaryError = "기념일 이름과 날짜를 모두 입력해주세요."
        }

        return errors.hasError ? errors : nil
    }
}
