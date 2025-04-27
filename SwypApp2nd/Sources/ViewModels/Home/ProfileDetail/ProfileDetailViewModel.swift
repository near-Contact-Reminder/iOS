import Foundation

class ProfileDetailViewModel: ObservableObject {
    @Published var people: Friend
    @Published var checkInRecords: [CheckInRecord] = []
    
    var canCheckInToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())

        // createdAt이 오늘 && isChecked true
        return !checkInRecords.contains { record in
            let recordDate = Calendar.current.startOfDay(for: record.createdAt)
            return recordDate == today && record.isChecked
        }
    }
    
    init(people: Friend) {
        self.people = people
        fetchFriendDetail(friendId: people.id)
        fetchFriendRecords(friendId: people.id)
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
                                    id: $0.id,
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
    
    // 친구 삭제 API 사용 메소드
    func deleteFriend(friendId: UUID, completion: @escaping () -> Void) {
        guard let token = UserSession.shared.user?.serverAccessToken else { return }
        
        BackEndAuthService.shared.deletFriend(friendId: friendId, accessToken: token) { result in
            switch result {
            case .success:
                print("🟢 [ProfileDetailViewModel] 친구 삭제 성공")
                completion()
            case .failure(let error):
                print("🔴 [ProfileDetailViewModel] 친구 삭제 실패: \(error)")
            }
        }
    }
    
    // 친구 챙김 기록 API
    func fetchFriendRecords(friendId: UUID) {
        guard let token = UserSession.shared.user?.serverAccessToken else { return }
        
        BackEndAuthService.shared.getFriendRecords(friendId: friendId, accessToken: token) { result in
            switch result {
            case .success(let checkInRecords):
                DispatchQueue.main.async {
                    self.checkInRecords = checkInRecords.sorted { $0.createdAt > $1.createdAt }
                }
                    
            case .failure(let error):
                print("🔴 [ProfileDetailViewModel] 친구 챙김 로그 가져오기 실패: \(error)")
            }
        }
    }
    
    func checkFriend() {
        guard let token = UserSession.shared.user?.serverAccessToken else {
            return
        }
            
        BackEndAuthService.shared
            .postFriendCheck(
                friendId: people.id,
                accessToken: token
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let message):
                        print("🟢 [ProfileDetailViewModel] 챙김 성공: \(message)")
                        self.fetchFriendDetail(friendId: self.people.id)
                        self.fetchFriendRecords(friendId: self.people.id)
                    case .failure(let error):
                        print("🔴 [ProfileDetailViewModel] 챙김 실패: \(error)")
                    }
                }
            }
    }
}
