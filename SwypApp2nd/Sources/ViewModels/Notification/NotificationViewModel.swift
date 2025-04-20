import SwiftUI
import CoreData
import Combine

class NotificationViewModel: ObservableObject {
    
    private let reminderRepo = ReminderRepository()
    private var cancellables = Set<AnyCancellable>()
    private let context = CoreDataStack.shared.context
    
    @Published var path: [AppRoute] = []
    @Published var reminders: [ReminderEntity] = []
    @Published var badgeCount: Int = 0
    @Published var selectedPerson: PersonEntity? = nil
    
    init() {
        loadAllReminders() // CoreData에서 기존 리마인더 불러오기
        setBadgeCount() // 뱃지 숫자 세팅
        observeReminderAdded() // 알림 구독해서 새로 생긴 리마인더 감지 -> 추후 코멘트 아웃
    }
    
    func loadAllReminders() {
        setBadgeCount()
        reminders = reminderRepo.fetchAllReminders()
    }
    
    // MARK: - 비동기로 안 읽은 알림 수 계산해서 뱃지 업데이트 (홈에서 종버튼에 사용)
    func setBadgeCount() {
        $reminders
            .map { $0.filter { !$0.isRead }.count } // 안 읽은 알림 개수 계산
            .assign(to: \.badgeCount, on: self)
            .store(in: &cancellables)
    }
    
    
    //MARK: - Inbox View에서 알림 스와이프해서 삭제 (알림 자체가 삭제되는 것 아님!)
    func deleteReminder(indexSet: IndexSet) {
        let sorted = visibleReminders.sorted(by: { $0.date > $1.date })
        let targets = indexSet.map { sorted[$0] }
        targets.forEach { reminderRepo.deleteReminder($0) }
        loadAllReminders()
    }
    
    //MARK: - Inbox View에서 알림 전체 삭제 (알림 자체가 삭제되는 것 아님!)
    func deleteAllReminders() {
        for reminder in visibleReminders {
            reminderRepo.deleteReminder(reminder)
        }
        loadAllReminders()
    }
    
    // MARK: - 알림에 연결된 사람 가지고 오고 해당 프로필 상세로 내비게이션 경로 설정
    func navigateFromNotification(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        print("알림 수신: \(userInfo)")
        
        guard let person = reminderRepo.fetchPerson(from: userInfo) else { return }
        
        DispatchQueue.main.async {
            self.path = [.person(person)]  // TODO
        }
    }
    
    // MARK: - 알림 읽음 설정
    func markAsRead(_ reminder: ReminderEntity) {
        reminderRepo.markAsRead(reminder)
        loadAllReminders()
    }
    
    // MARK: - 새로운 알림 구독 (디버깅 목적)
    private func observeReminderAdded() {
        NotificationCenter.default.publisher(for: NSNotification.Name("NewReminderAdded"))
            .sink { notification in
                guard
                    let userInfo = notification.userInfo,
                    let idString = userInfo["personID"] as? String,
                    let typeRaw = userInfo["type"] as? String,
                    let type = NotificationType(rawValue: typeRaw)
                else {
                    print("❌ 알림 파싱 실패")
                    return
                }
                print("📩 NewReminderAdded 받음 uuid: \(idString), type: \(type)")
            }
            .store(in: &cancellables)
    }
    
     // MARK: - 친구 목록을 순회하며 전체 안부 알림 설정
    func scheduleAnbu(people: [Friend]) {
         // 1. 내부 알림 설정 체크
        guard UserDefaults.standard.bool(forKey: "isNotificationOn") else {
            print("🛑 알림 꺼져 있어서 일반 알림 예약 안 함")
            return
        }
        
         // 2. initial permission 체크
        NotificationManager.shared.requestPermissionIfNeeded()
        
         // 3. friend 별로 안부 주기 설정
        for friend in people {
            
            guard let personId = friend.entity?.id.uuidString else {
                print("❌ 친구에 연결된 PersonEntity 없음")
                return
            }

            guard let (content, trigger, scheduledDate) = setAnbu(person: friend, id: personId) else {
                print("❌ 알림 생성 실패")
                return
            }
            
            let genRequest = UNNotificationRequest(identifier: personId, content: content, trigger: trigger)
            
            let center = UNUserNotificationCenter.current()
            center.add(genRequest)
            
             // person entity 찾기
//            reminderRepo.addReminder(for: friend, type: .regular, scheduledDate: scheduledDate)
            try? context.save()
             // 2. 백엔드에 전송
            guard let token = TokenManager.shared.get(for: .server) else {
                print("⚠️ 서버 accessToken 없음 - 백엔드 요청 생략")
                return
            }
            
            BackEndAuthService.shared.sendReminder(friendId: friend.id, accessToken: token) { result in
                switch result {
                case .success:
                    print("📬 리마인더 서버 전송 완료")
                case .failure(let error):
                    print("📭 리마인더 서버 전송 실패: \(error)")
                }
            }
        }
        // 3. 뷰에도 반영할 수 있게 fetch
        loadAllReminders()
    }
    
     // MARK: - 친구 개개인당 안부 알림 설정
    func setAnbu(person: Friend, id: String) -> (content: UNMutableNotificationContent, trigger: UNNotificationTrigger, scheduledDate: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        guard let frequency = CheckInFrequency(rawValue: person.frequency?.rawValue ?? CheckInFrequency.none.rawValue), let nextDate = now.nextCheckInDateValue(for: frequency)  else {
            print("❌ 잘못된 리마인더 주기")
            return nil
        }
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: nextDate)
        dateComponents.hour = 22
        dateComponents.minute = 0
        guard let scheduledDate = calendar.date(from: dateComponents) else { return nil }
        
        let content = UNMutableNotificationContent()
        content.title = "📌 챙김 알림"
        content.body = "\(person.name)님에게 연락해보세요!"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["personID": id, "type": "regular"]
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        return (content, trigger, scheduledDate)
    }
    
    
     // MARK: - 프로필 상세 수정뷰에서 친구 별 생일 혹은 기념일 설정
    func setSpecialReminder(person: Friend, id: String) {
        
        guard UserDefaults.standard.bool(forKey: "isNotificationOn") else {
            print("🛑 알림 꺼져 있어서 일반 알림 예약 안 함")
            return
        }
        
        NotificationManager.shared.requestPermissionIfNeeded()
        
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let now = Date()
        
        if let birthday = person.birthDay,
           let adjustedBday = Date.nextSpecialDate(from: birthday) {
           
            let content = UNMutableNotificationContent()
            content.title = "🎂 생일 알림"
            content.body = "\(person.name)님의 생일이에요! 연락해보세요!"
            content.sound = .default
            content.badge = 1
            
            var birthdayComponents = calendar.dateComponents([.year, .month, .day], from: adjustedBday)
            birthdayComponents.hour = 8
            birthdayComponents.minute = 0
            
            guard let scheduledDate = calendar.date(from: birthdayComponents) else {
                print("❌ 생일 날짜 생성 실패")
                return
            }

//            reminderRepo.addReminder(for: person, type: NotificationType.birthday, scheduledDate: scheduledDate)
            
            content.userInfo = ["personID": "\(id)", "type": "birthday"]
            
            try? context.save()
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: birthdayComponents, repeats: true)
            
            let bdayRequest = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(bdayRequest)
        }
            
            if let anniversary = person.anniversary?.Date,
                let adjustedAnniversary = Date.nextSpecialDate(from: anniversary) {
                let content = UNMutableNotificationContent()
                content.title = "💖 기념일 알림"
                content.body = "\(person.name)님과의 기념일이에요! 연락해보세요!"
                content.sound = .default
                content.badge = 1
                
                var anniversaryComponents = calendar.dateComponents([.year, .month, .day], from: adjustedAnniversary)
                anniversaryComponents.hour = 08
                anniversaryComponents.minute = 00
                
                guard let scheduledDate = calendar.date(from: anniversaryComponents) else { return }
                
//                reminderRepo.addReminder(for:person, type: NotificationType.anniversary
//                                         , scheduledDate: scheduledDate)
                
                content.userInfo = ["personID": "\(id)", "type": "anniversary"]
                
                try? context.save()
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: anniversaryComponents, repeats: true)
                let anniRequest = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(anniRequest)
            }
        }
    }


extension NotificationViewModel {
    var visibleReminders: [ReminderEntity] {
        let today = Calendar.current.startOfDay(for: Date())
        return reminders
                .filter { Calendar.current.startOfDay(for: $0.date) <= today }
                    .sorted(by: { $0.date > $1.date })
    }
}

