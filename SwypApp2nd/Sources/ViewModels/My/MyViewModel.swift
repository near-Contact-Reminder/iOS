import SwiftUI
import Combine

class MyViewModel: ObservableObject {
    @Published var isNotificationOn: Bool = UserDefaults.standard.bool(forKey: "isNotificationOn")
    @Published var showSettingsAlert: Bool = false
    
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
}
