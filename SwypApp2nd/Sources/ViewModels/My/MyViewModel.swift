import SwiftUI
import Combine

class MyViewModel: ObservableObject {
    
    @Published var isNotificationOn: Bool = UserDefaults.standard.bool(forKey: "isNotificationOn")
    @Published var showSettingsAlert: Bool = false
    @Published var selectedReason: String = ""
    @Published var customReason: String = ""
    @Published var showConfirmAlert: Bool = false
    var isValidCustomReason: Bool {
            selectedReason != "기타" || (customReason.count >= 1 && customReason.count <= 200)
        }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 토글 감지
        $isNotificationOn
            .removeDuplicates()
            .sink { [weak self] newValue in
                guard let self = self else { return }
                
                if newValue {
                    self.handleToggleOn()
                }
                UserDefaults.standard.set(newValue, forKey: "isNotificationOn")
            }
            .store(in: &cancellables)
    }

    
    func loadInitialState() {
        NotificationManager.shared.checkAuthorizationStatus { status in
            switch status {
            case .authorized:
                self.isNotificationOn = !UserDefaults.standard.bool(forKey: "didManuallyDisableNotification")
            default:
                self.isNotificationOn = false
            }
        }
    }
    
    private func handleToggleOn() {
        NotificationManager.shared.checkAuthorizationStatus { status in
            switch status {
                case .denied, .notDetermined:
                    self.showSettingsAlert = true
                    self.isNotificationOn = false
                    
                case .authorized, .provisional:
                    if UserDefaults.standard.bool(forKey: "didManuallyDisableNotification") {
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
