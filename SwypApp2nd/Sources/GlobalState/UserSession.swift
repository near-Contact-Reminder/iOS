import Combine

class UserSession: ObservableObject {
    static let shared = UserSession()
    
    @Published var isLoggedIn = false
    @Published var user: User?

    func updateUser(_ user: User) {
        self.user = user
        self.isLoggedIn = true
    }

    func kakaoLogout() {
        self.user = nil
        self.isLoggedIn = false
    }
    
    func appleLogout() {
        self.user = nil
        self.isLoggedIn = false
    }
}
