import Foundation
import Combine
import UIKit

class ContactFrequencySettingsViewModel: ObservableObject {
    @Published var people: [Friend] = []
    @Published var isUnified: Bool = false
    @Published var unifiedFrequency: CheckInFrequency? = nil
    
    var canComplete: Bool {
        if isUnified {
            // unifiedFrequency가 nil이 아니고 .none이 아닐때 true
            return unifiedFrequency != nil && unifiedFrequency != CheckInFrequency.none
        } else {
            // 각각의 사람 frequency가 nil 아니고 .none 아닐떄
            return people.allSatisfy {
                $0.frequency != nil && $0.frequency != CheckInFrequency.none
            }
        }
    }
    
    func toggleUnifiedFrequency(_ enabled: Bool) {
        isUnified = enabled
    }
    
    func calculateNextContactDate(for frequency: CheckInFrequency) -> Date {
        return Date().nextCheckInDateValue(for: frequency) ?? Date()
    }
    
    func updateFrequency(for person: Friend, to frequency: CheckInFrequency) {
        guard !isUnified else { return } // 한 번에 설정 중이면 무시..?
        guard let index = people.firstIndex(of: person) else { return }
        let nextDate = calculateNextContactDate(for: frequency)
        people[index].frequency = frequency
        people[index].nextContactAt = nextDate
    }
    
    func applyUnifiedFrequency(_ frequency: CheckInFrequency) {
        unifiedFrequency = frequency
        if isUnified {
            let nextDate = calculateNextContactDate(for: frequency)
            for i in people.indices {
                people[i].frequency = frequency
                people[i].nextContactAt = nextDate
            }
        }
    }
    
    // RegisterViewModel에서 선택한 연락처 받아오는 메소드, 기존 친구(friends)에 이미 있는 친구는 제외하고, 새 친구만 저장
    func setPeople(from contacts: [Friend]) {
        let existing = UserSession.shared.user?.friends ?? []
        let existingIds = Set(existing.map { $0.id })

        let newFriends = contacts.filter { !existingIds.contains($0.id) }
        let allowedCount = max(0, 10 - existing.count)

        self.people = Array(newFriends.prefix(allowedCount))
            
        if newFriends.count > allowedCount {
            print("⚠️ 최대 10명까지만 등록할 수 있어요.")
        }
        for i in people.indices {
            let original = newFriends.first(where: { $0.id == people[i].id })
            people[i].relationship = original?.relationship
            people[i].memo = original?.memo
            people[i].birthDay = original?.birthDay
            people[i].anniversary = original?.anniversary
            people[i].phoneNumber = original?.phoneNumber
        }
    }
    
    /// 카카오 이미지 다운로드
    func downloadKakaoImageData(completion: @escaping ([Friend]) -> Void) {
        var updatedPeople = people
        let group = DispatchGroup()
        
        for (index, friend) in people
            .enumerated() where friend.source == .kakao {
            guard let urlString = friend.imageURL else {
                print("🔴 [downloadKakaoImageData] \(friend.name) imageURL nil")
                continue
            }
            group.enter()
            
            SnsAuthService.shared.downloadImageData(from: urlString) { data in
                if let data = data, let image = UIImage(data: data) {
                    updatedPeople[index].image = image
                    print("🟢 [ContactFrequencySettingsViewModel] \(friend.name) 카카오 이미지 다운로드 성공")
                } else {
                    print("🔴 [ContactFrequencySettingsViewModel] \(friend.name) 카카오 이미지 다운로드 실패")
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.people = updatedPeople
            completion(updatedPeople)
        }
    }
    
    func uploadAllFriendsToServer(_ friends: [Friend], completion: @escaping () -> Void) {
        guard let accessToken = UserSession.shared.user?.serverAccessToken else { return }
        
        BackEndAuthService.shared.sendInitialFriends(friends: friends, accessToken: accessToken) { result in
            switch result {
            case .success(let registeredFriends):
                let group = DispatchGroup()
                
                // 서버에서 받은 id로 업데이트
                for friendWithURL in registeredFriends {
                    if let index = self.people.firstIndex(
                        where: { $0.name == friendWithURL.name
                        }) {
                        self.people[index].id = UUID(
                            uuidString: friendWithURL.friendId
                        ) ?? self
                            .people[index].id
                        self.people[index].fileName = friendWithURL.fileName
                        self.people[index].anniversary?.id = friendWithURL.anniversary?.id
                        print( "🟢 [ContactFrequencySettingsViewModel] 서버 ID로 업데이트됨: \(self.people[index].name) → \(self.people[index].id)")
                        print( "🟢 [ContactFrequencySettingsViewModel] 서버 ID로 fileName 업데이트됨: \(self.people[index].name)의 fileName \(String(describing: self.people[index].fileName))")
                    }
                }
                
                // 이미지 업로드
                for friendWithURL in registeredFriends {
                    if let url = friendWithURL.preSignedImageUrl,
                       let localFriend = friends.first(where: { $0.name == friendWithURL.name }),
                       let image = localFriend.image?.jpegData(compressionQuality: 0.4) {
                        
                        print("🟡 [ContactFrequencySettingsViewModel] 업로드 시도 → 이름: \(localFriend.name)")
                        print("🟡 [ContactFrequencySettingsViewModel] 업로드 파일 이름 예상: \(localFriend.fileName ?? "nil")")
                        print("🟡 [ContactFrequencySettingsViewModel] 업로드 대상 URL: \(url)")
                        
                        group.enter()
                        BackEndAuthService.shared.uploadImageWithPresignedURL(imageData: image, presignedURL: url, contentType: "image/jpeg") { success in
                            if success {
                                print("🟢 [ContactFrequencySettingsViewModel] \(friendWithURL.name)의 이미지 업로드: 성공")
                            } else {
                                print("🔴 [ContactFrequencySettingsViewModel] \(friendWithURL.name)의 이미지 업로드: 실패")
                            }
                            group.leave()
                        }
                    } else {
                        print("🔴 이미지 업로드 조건 실패 - 이름: \(friendWithURL.name)")
                        if friendWithURL.preSignedImageUrl == nil {
                            print("🔴 preSignedImageUrl 없음")
                        }
                        if friends
                            .first(where: { $0.name == friendWithURL.name }) == nil {
                            print("🔴 localFriend 매칭 실패")
                        }
                        if let localFriend = friends.first(where: { $0.name == friendWithURL.name }), localFriend.image == nil {
                            print("🔴 localFriend.image == nil")
                        }
                    }
                }
                group.notify(queue: .main) {
                    print("🟢 [ContactFrequencySettingsViewModel] 모든 이미지 업로드 완료, completion 호출")
                    completion()
                }
            case .failure(let error):
                print("🔴 [ContactFrequencySettingsViewModel] 친구 등록 실패: \(error)")
            }
        }
    }
}
