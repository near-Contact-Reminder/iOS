import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var peoples: [Friend] = []
    
//    init() {
//        loadPeoplesFromUserSession()
//    }
//
//    @MainActor
//    func loadPeoplesFromUserSession() {
//        self.peoples = UserSession.shared.user?.contacts ?? []
//    }
}
