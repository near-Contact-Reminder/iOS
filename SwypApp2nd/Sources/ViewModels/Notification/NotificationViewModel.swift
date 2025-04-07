import SwiftUI
import UserNotifications
import CoreData
import Combine

class NotificationViewModel: ObservableObject {
    
    private let reminderRepo = ReminderRepository()
    private var cancellables = Set<AnyCancellable>()
    private let context = CoreDataStack.shared.context
    
    @Published var reminders: [ReminderEntity] = []
    @Published var badgeCount: Int = 0
    @Published var selectedPerson: PersonEntity? = nil
    
    
    init() {
        loadAllReminders()
        setBadgeCount()
        observeReminderAdded()
    }
    
    func loadAllReminders() {
        setBadgeCount()
       reminders = reminderRepo.fetchAllReminders()
    }
    
    func setBadgeCount() {
        $reminders
            .map { $0.filter { !$0.isRead }.count } // 안 읽은 알림 개수 계산
            .assign(to: \.badgeCount, on: self)
            .store(in: &cancellables)
    }
            
    // 새로운 알림 추가
    func addNewReminder(for person: PersonEntity) {
        reminderRepo.addReminder(for: person)
        loadAllReminders()  // UI 업데이트
    }
    
    func deleteReminder(indexSet: IndexSet) {
        for index in indexSet {
           let reminderToDelete = reminders[index]
           reminderRepo.deleteReminder(reminderToDelete) // CoreData에서 삭제
       }
        reminders.remove(atOffsets: indexSet)
        loadAllReminders() // UI 업데이트
    }
    
    func deleteAllReminders() {
        
        for reminder in reminders {
            reminderRepo.deleteReminder(reminder)
        }
        loadAllReminders()
    }
        
    func handleNotification(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        print("알림 수신: \(userInfo)")
        
        guard let person = reminderRepo.fetchPerson(from: userInfo) else { return }
        self.selectedPerson = person
    }
    
    func markAsRead(_ reminder: ReminderEntity) {
        reminderRepo.markAsRead(reminder)
        loadAllReminders()
    }
    
    
    private func observeReminderAdded() {
        NotificationCenter.default.publisher(for: NSNotification.Name("NewReminderAdded"))
            .compactMap { $0.userInfo?["personID"] as? String }
            .compactMap { UUID(uuidString: $0) }
            .sink { [weak self] uuid in
                print("📩 NewReminderAdded 받음. uuid: \(uuid)")
                guard let self = self else { return }
                // CoreData에서 해당 PersonEntity fetch
                let request: NSFetchRequest<PersonEntity> = PersonEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                
                if let person = try? self.context.fetch(request).first {
                    self.scheduleReminder(for: person)
                    self.scheduleBirthdayAnniversaryReminder(for: person)
                }
            }
            .store(in: &cancellables)
    }
    
    func requestPermissionIfNeeded() {
            let key = "didRequestNotificationPermission"
        
            // 이미 권한 요청 완료
            guard !UserDefaults.standard.bool(forKey: key) else { return }

            // 최초 한 번만 실행
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if error == nil {
                    DispatchQueue.main.async {
                            UserDefaults.standard.set(true, forKey: key)
                        }
                }
            }
        }
    
    func scheduleReminder(for person: PersonEntity) {
        requestPermissionIfNeeded()
        
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "📌 챙김 알림"
        content.body = "\(person.name)님에게 연락해보세요!"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["personID": person.id.uuidString]
        
        var trigger: UNCalendarNotificationTrigger?
        
        let calendar = Calendar.current
        let now = Date()
        var dateComponents = calendar.dateComponents([.hour, .minute], from: now)
        dateComponents.hour = 00  // TODO: 고도화: custom 시간, 현재는 오전 9시에 알림 설정
        dateComponents.minute = 26
        
        // "매일", "매주", "2주", "매달", "매분기", "6개월", "매년"
        switch person.reminderInterval {
        case "매일":
            break
        case "매주": // TODO: 무슨요일?
            dateComponents.weekday = 2 // TODO: view에서 유저가 선택하게 하기
        case "2주":
            let twoWeeksLater = calendar.date(byAdding: .day, value: 14, to: now)!
            dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: twoWeeksLater)
        case "매달":
            dateComponents.day = calendar.component(.day, from: now)
        default:
            return
        }
        
        trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: person.reminderInterval != "2주")
        let normalRequest = UNNotificationRequest(identifier: person.id.uuidString, content: content, trigger: trigger)

        center.add(normalRequest)
    }
    
    func scheduleBirthdayAnniversaryReminder(for person: PersonEntity) {
        
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        
        content.title = "🎉 특별한 날 알림"
        content.sound = .default
        
        let calendar = Calendar.current
        
        if let birthday = person.birthday {
            content.body = "\(person.name)님의 생일이에요! 연락해보세요! 🎂"
            var birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)
            birthdayComponents.hour = 0
            birthdayComponents.minute = 27
            let trigger = UNCalendarNotificationTrigger(dateMatching: birthdayComponents, repeats: true)
            let birthRequest = UNNotificationRequest(identifier: "\(person.id)-birthday", content: content, trigger: trigger)
            center.add(birthRequest)
        }
        
        if let anniversary = person.anniversary {
            content.body = "\(person.name)님과의 기념일이에요! 연락해보세요! 🎉"
            var anniversaryComponents = calendar.dateComponents([.month, .day], from: anniversary)
            anniversaryComponents.hour = 0
            anniversaryComponents.minute = 28
            let trigger = UNCalendarNotificationTrigger(dateMatching: anniversaryComponents, repeats: true)
            let anniRequest = UNNotificationRequest(identifier: "\(person.id)-anniversary", content: content, trigger: trigger)
            center.add(anniRequest)
        }
    }
}
    

