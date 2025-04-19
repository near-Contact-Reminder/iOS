import Foundation

class ProfileDetailViewModel: ObservableObject {
    @Published var people: Friend
    
    init(people: Friend) {
        self.people = people
        fetchFriendDetail(friendId: people.id)
    }
    
    // 친구 상세 API 사용 메소드
    func fetchFriendDetail(friendId: UUID) {
        guard let token = UserSession.shared.user?.serverAccessToken else { return }
        
        BackEndAuthService.shared.getFriendDetail(friendId: friendId, accessToken: token) { result in
            switch result {
            case .success(let friendDetail):
                DispatchQueue.main.async {
                    self.people = friendDetail
                }
            case .failure(let error):
                print("🔴 [ProfileDetailViewModel] 친구 상세 정보 가져오기 실패: \(error)")
            }
        }
    }
}
