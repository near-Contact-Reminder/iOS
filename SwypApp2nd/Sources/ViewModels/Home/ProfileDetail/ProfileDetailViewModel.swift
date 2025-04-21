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
                    print("self.people.id.uuidString = \(self.people.id.uuidString)")
                    print("friendDetail.friendId = \(friendDetail.friendId)")
                    
                    if self.people.id.uuidString.lowercased() == friendDetail.friendId {
                        self.people.imageURL = friendDetail.imageUrl
                        self.people.relationship = friendDetail.relation
                        self.people.frequency = friendDetail.contactFrequency
                        self.people.birthDay = friendDetail.birthDay?.toDate()
                        self.people.anniversary = friendDetail.anniversaryList?.first
                            .flatMap {
                                AnniversaryModel(
                                    title: $0.title,
                                    Date: $0.Date
                                )
                            }
                        self.people.memo = friendDetail.memo
                        self.people.phoneNumber = friendDetail.phone
                        print("🟢 [ProfileDetailViewModel] people 업데이트 성공 : \(String(describing: self.people.phoneNumber))")
                    }
                    
                }
            case .failure(let error):
                print("🔴 [ProfileDetailViewModel] 친구 상세 정보 가져오기 실패: \(error)")
            }
        }
    }
}
