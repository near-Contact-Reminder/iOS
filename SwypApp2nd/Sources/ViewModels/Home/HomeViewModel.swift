import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var peoples: [Friend] = []
    /// 내 사람들
    @Published var allFriends: [Friend] = []
    /// 이번달 챙길 사람
    @Published var thisMonthFriends: [Friend] = []
    
    init() {
        loadPeoplesFromUserSession()
    }

    func loadPeoplesFromUserSession() {
        DispatchQueue.main.async {
            self.peoples = UserSession.shared.user?.friends ?? []
        }
    }
}
