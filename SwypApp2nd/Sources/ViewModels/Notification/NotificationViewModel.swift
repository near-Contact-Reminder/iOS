import SwiftUI
import CoreData
import Combine

class NotificationViewModel: ObservableObject {
    
    private let reminderRepo = ReminderRepository()
    private var cancellables = Set<AnyCancellable>()
    private let context = CoreDataStack.shared.context
    
    @Published var navigateToPerson: Friend?
    @Published var reminders: [ReminderEntity] = []
    @Published var showBadge: Bool = false
    @Published var showToast: Bool = false
    
    init() {
        loadAllReminders() // CoreData에서 기존 리마인더 불러오기
        setShowBadge() // 뱃지 숫자 세팅
        observeReminderAdded() // 알림 구독해서 새로 생긴 리마인더 감지 -> 추후 코멘트 아웃
    }
    
    func loadAllReminders() {
        setShowBadge()
        reminders = reminderRepo.fetchAllReminders()
    }
    
    /// 비동기로 안 읽은 알림 수 계산해서 뱃지 업데이트 (홈에서 종버튼에 사용)
    func setShowBadge() {
        $reminders
            .receive(on: DispatchQueue.main)
            .map { reminders in
                        reminders.contains(where: { $0.isTriggered && !$0.isRead }
                )
            }
            .assign(to: \.showBadge, on: self)
            .store(in: &cancellables)
    }
    
    
    /// Inbox View에서 알림 스와이프해서 삭제 (알림 자체가 삭제되는 것 아님!)
    func deleteReminder(indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let reminderToDelete = visibleReminders[index]
        
        context.delete(reminderToDelete) // CoreData에서도 삭제

        do {
            try context.save() // CoreData에 반영
            print("✅ Reminder 삭제 성공")
        } catch {
            print("❌ CoreData 저장 실패: \(error.localizedDescription)")
        }
        if let indexInArray = reminders.firstIndex(of: reminderToDelete) {
                reminders.remove(at: indexInArray)
            }
    }
    
    /// Inbox View에서 알림 전체 삭제 (알림 자체가 삭제되는 것 아님!)
    func deleteAllReminders() {
        let toRemove = visibleReminders
        
        toRemove.forEach { reminder in
                context.delete(reminder) // CoreData에서도 삭제
            }

            do {
                try context.save() // CoreData에 반영
                print("✅ 모든 Reminder 삭제 성공")
            } catch {
                print("❌ CoreData 저장 실패: \(error.localizedDescription)")
            }
        reminders.removeAll { toRemove.contains($0) }

    }

    
    func deleteRemindersEternally(person: Friend) {
        
        let selectedReminders = reminderRepo.fetchReminders(person: person)
        let ids = Array(reminders).compactMap { $0.id.uuidString }
        
        // 1. 예약된 알림 삭제
        NotificationManager.shared.center.removePendingNotificationRequests(withIdentifiers: ids)
        NotificationManager.shared.center.removeDeliveredNotifications(withIdentifiers: ids)
           print("🗑️ 스케줄된 알림 삭제: \(ids)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationManager.shared.center.getPendingNotificationRequests { requests in
                print("남아 있는 스케줄알람 개수: \(requests.count)")
            }
        }
           
       // 2. CoreData Reminder 삭제
       for reminder in selectedReminders {
           context.delete(reminder)
       }
        do {
            try context.save() // CoreData에서 삭제 반영
            print("✅ \(person.name)의 Reminder 삭제 성공")
        } catch {
            print("❌ Reminder 삭제 실패: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            self.reminders.removeAll { reminder in
                selectedReminders.contains(reminder)
            }
        }
    }

    
    // MARK: - 알림에 연결된 사람 가지고 오고 해당 프로필 상세로 내비게이션 경로 설정
    func navigateFromNotification(userInfo: [AnyHashable: Any]) {

        guard let person = reminderRepo.fetchPerson(from: userInfo) else { return }
        
        DispatchQueue.main.async {
            self.navigateToPerson = person
        }
    }
    
    // MARK: - 알림 읽음 설정
    func isRead(_ reminder: ReminderEntity) {
        reminderRepo.markAsRead(reminder)
        loadAllReminders()
    }
    
    func isTriggered(reminderId: UUID) {
        
        let request: NSFetchRequest<ReminderEntity> = ReminderEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", reminderId as CVarArg)
        if let reminder = try? context.fetch(request).first {
            reminderRepo.markAsTriggered(reminder)
        }
       
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
    func scheduleNotifications(people: [Friend]) {
         // 1. 내부 알림 설정 체크
//        guard UserDefaults.standard.bool(forKey: "isNotificationOn") else {
//            print("🛑 알림 꺼져 있어서 일반 알림 예약 안 함")
//            return
//        }
        
         // 2. initial permission 체크
        NotificationManager.shared.requestPermissionIfNeeded()
        
         // 3. friend 별로 안부 주기 설정
        for friend in people {
            
//            guard let personId = friend.entity?.id.uuidString else {
//                print("❌ 친구에 연결된 PersonEntity 없음")
//                return
//            }
            if (friend.birthDay != nil) {
                setBDayReminder(person: friend)
            }
                
            if (friend.anniversary != nil) {
                setAnniversaryReminder(person: friend)
            }
            
            guard let (content, trigger, scheduledDate, reminderId) = setAnbu(person: friend) else {
                print("❌ 알림 생성 실패")
                return
            }
            
            let genRequest = UNNotificationRequest(identifier: reminderId.uuidString, content: content, trigger: trigger)
            
            NotificationManager.shared.center.add(genRequest)
            
             // person entity 찾기
            reminderRepo.addReminder(person: friend, reminderId: reminderId, type: NotificationType.regular, scheduledDate: scheduledDate)
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
        DispatchQueue.main.async {
            self.showToast = true
        }
    }
    
     // MARK: - 친구 개개인당 안부 알림 설정
    func setAnbu(person: Friend) -> (content: UNMutableNotificationContent, trigger: UNNotificationTrigger, scheduledDate: Date, id : UUID)? {
        
        let reminderID = UUID()
        let calendar = Calendar.current
        let now = Date()

        guard let frequency = CheckInFrequency(rawValue: person.frequency?.rawValue ?? CheckInFrequency.none.rawValue), let nextDate = now.nextCheckInDateValue(for: frequency)  else {
            
            print("❌ 잘못된 리마인더 주기")
            return nil
        }
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: nextDate)
       dateComponents.hour = 9
       dateComponents.minute = 0

//        테스트용 
        // if frequency == .daily {
        //     let future = Calendar.current.date(byAdding: .second, value: 20, to: Date())!
        //     dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: future)
        // }
        
        guard let scheduledDate = calendar.date(from: dateComponents) else { return nil }

        
        let content = UNMutableNotificationContent()
        content.title = "📌 챙김 알림"
        content.body = "\(person.name)님에게 연락해보세요!"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["personID": person.id.uuidString, "reminderID" : reminderID.uuidString, "type": "regular"]
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        print("🟢 [NotificationViewModel] \(person.name) 알림 등록 완료")
        // ✅ 등록된 알림 확인 로그 TODO 나중에 삭제
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationManager.shared.center.getPendingNotificationRequests { requests in
                for req in requests {
                    print("🧾 예약된 알림: \(req.identifier), trigger: \(req.trigger!)")
                }
            }
        }
        return (content, trigger, scheduledDate, reminderID)
    }
    
    
     // MARK: - 프로필 상세 수정뷰에서 친구 별 생일 혹은 기념일 설정
    func setBDayReminder(person: Friend) {
        
//        guard UserDefaults.standard.bool(forKey: "isNotificationOn") else {
//            print("🛑 알림 꺼져 있어서 일반 알림 예약 안 함")
//            return
//        }
        
        NotificationManager.shared.requestPermissionIfNeeded()
        let calendar = Calendar.current
        let birthdayId = UUID()
        
        if let birthday = person.birthDay,
           let adjustedBday = Date.nextSpecialDate(from: birthday) {
        
            var birthdayComponents = calendar.dateComponents([.year, .month, .day], from: adjustedBday)
            birthdayComponents.hour = 8
            birthdayComponents.minute = 00
            
            guard let scheduledDate = calendar.date(from: birthdayComponents) else {
                print("❌ 생일 날짜 생성 실패")
                return }

            reminderRepo.addReminder(person: person, reminderId: birthdayId, type: NotificationType.birthday, scheduledDate: scheduledDate)
            
            let content = UNMutableNotificationContent()
            content.title = "🎂 생일 알림"
            content.body = "\(person.name)님의 생일이에요! 연락해보세요!"
            content.sound = .default
            content.badge = 1
            content.userInfo = ["personID": person.id.uuidString, "reminderID": birthdayId.uuidString, "type": "birthday"]
            
            print("🟢 [NotificationViewModel] \(person.name)의 생일 알림 등록 완료")

            try? context.save()
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: birthdayComponents, repeats: true)
            
            let bdayRequest = UNNotificationRequest(identifier: birthdayId.uuidString, content: content, trigger: trigger)
            
            NotificationManager.shared.center.add(bdayRequest) { error in
                if let error = error {
                    print("🔴 생일 알림 등록 실패: \(error.localizedDescription)")
                } else {
                    print("🟢 생일 알림 등록 성공: \(bdayRequest.identifier)")
                }
            }
            
            guard let token = TokenManager.shared.get(for: .server) else {
                print("⚠️ 서버 accessToken 없음 - 백엔드 요청 생략")
                return
            }
            
            BackEndAuthService.shared.sendReminder(friendId: person.id, accessToken: token) { result in
                switch result {
                case .success:
                    print("📬 리마인더 서버 전송 완료")
                case .failure(let error):
                    print("📭 리마인더 서버 전송 실패: \(error)")
                }
            }
        }
    }
    
    func setAnniversaryReminder(person: Friend) {
        
        NotificationManager.shared.requestPermissionIfNeeded()
        let calendar = Calendar.current
        let anniversaryId = UUID()
        
        if let anniversary = person.anniversary?.Date,
            let adjustedAnniversary = Date.nextSpecialDate(from: anniversary) {
            
            var anniversaryComponents = calendar.dateComponents([.year, .month, .day], from: adjustedAnniversary)
            anniversaryComponents.hour = 08
            anniversaryComponents.minute = 00
            
            guard let scheduledDate = calendar.date(from: anniversaryComponents) else {
                print("🔴 기념일 날짜 생성 실패")
                return }
            
            reminderRepo.addReminder(person: person, reminderId: anniversaryId, type: NotificationType.anniversary, scheduledDate: scheduledDate)
            
            let content = UNMutableNotificationContent()
            content.title = "💖 기념일 알림"
            content.body = "\(person.name)님과의 기념일이에요! 연락해보세요!"
            content.sound = .default
            content.badge = 1
            
            content.userInfo = ["personID": person.id.uuidString, "reminderID": anniversaryId.uuidString, "type": "anniversary"]
           
            print("🟢 [NotificationViewModel] \(person.name)의 기념일 알림 등록 완료")
            try? context.save()
                
            let trigger = UNCalendarNotificationTrigger(dateMatching: anniversaryComponents, repeats: true)
            let anniRequest = UNNotificationRequest(identifier: anniversaryId.uuidString, content: content, trigger: trigger)
            NotificationManager.shared.center.add(anniRequest) { error in
                if let error = error {
                    print("🔴 기념일 알림 등록 실패: \(error.localizedDescription)")
                } else {
                    print("🟢 기념일 알림 등록 성공: \(anniRequest.identifier)")
                }
            }
            guard let token = TokenManager.shared.get(for: .server) else {
                print("⚠️ 서버 accessToken 없음 - 백엔드 요청 생략")
                return
            }
            
            BackEndAuthService.shared.sendReminder(friendId: person.id, accessToken: token) { result in
                switch result {
                case .success:
                    print("📬 리마인더 서버 전송 완료")
                case .failure(let error):
                    print("📭 리마인더 서버 전송 실패: \(error)")
                }
            }
            
        }
        }
    }


extension NotificationViewModel {
    var visibleReminders: [ReminderEntity] {
        let today = Calendar.current.startOfDay(for: Date())
        return reminders
            .filter { $0.isTriggered }
            .sorted(by: { $0.date > $1.date })
    }
}
