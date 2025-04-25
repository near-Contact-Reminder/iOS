import SwiftUI
import Combine

class MyViewModel: ObservableObject {
//    
    @Published var isNotificationOn: Bool = false
    @Published var showSettingsAlert: Bool = false
    
    
    @Published var selectedReason: String = ""
    @Published var customReason: String = ""
    @Published var showConfirmAlert: Bool = false
    var isValidCustomReason: Bool {
            selectedReason != "기타" || (customReason.count >= 1 && customReason.count <= 200)
        }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        observeAppForeground()
     
    }

    // MARK: - 유저가 세팅 가서 알림 허용 했나 확인
    func observeAppForeground() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.checkNotificationStatusAfterSettings()
            }
            .store(in: &cancellables)
    }
    
    func checkNotificationStatusAfterSettings() {
            NotificationManager.shared.checkAuthorizationStatus { status in
                DispatchQueue.main.async {
                    switch status {
                    
                    case .authorized, .provisional:
                        print("🟢 [MyViewModel] 알림 수동 켬 처리")
                        UserDefaults.standard.set(false, forKey: "didManuallyDisableNotification")
                        self.isNotificationOn = true
                    
                    case .denied, .notDetermined:
                        self.isNotificationOn = false
                    
                    default:
                        break
                    }
                }
            }
        }
    
    // MARK: - 첫 로딩 때 유저가 알림 허용 했는지 확인
    func loadInitialState() {
        NotificationManager.shared.checkAuthorizationStatus { status in
            switch status {
            case .authorized:
                self.isNotificationOn = true
            default:
                self.isNotificationOn = false
            }
        }
    }
    
    func turnOffNotifications() {
        isNotificationOn = false
        NotificationManager.shared.disableNotifications()
    }

    
    func handleToggleOn() {
        NotificationManager.shared.checkAuthorizationStatus { status in
            switch status {
                case .denied, .notDetermined:
                    self.showSettingsAlert = true
                    self.isNotificationOn = false
                    
                case .authorized, .provisional:
                    if UserDefaults.standard.bool(forKey: "didManuallyDisableNotification") {
                        print("🔴 [MyViewModel] 알림 수동 끔 처리")
                        self.showSettingsAlert = true
                        self.isNotificationOn = false
                    }
                default:
                    break
                }
            }
    }
    
    func submitWithdrawal(loginType: LoginType, completion: @escaping (Bool) -> Void) {
        
        UserSession.shared.withdraw(loginType: loginType, selectedReason: selectedReason, customReason: customReason) { success in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
