import Foundation
import Combine
import UIKit

enum CheckInFrequency: String, CaseIterable, Identifiable, Codable {
    case none = "주기 선택"
    case daily = "매일"
    case weekly = "매주"
    case biweekly = "2주"
    case monthly = "매달"
    case semiAnnually = "6개월"
    
    var id: String { rawValue }
}

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
        guard let index = people.firstIndex(of: person) else { return }
        let nextDate = calculateNextContactDate(for: frequency)
        people[index].frequency = frequency
        people[index].nextContactAt = nextDate
    }
    
    func applyUnifiedFrequency(_ frequency: CheckInFrequency) {
        unifiedFrequency = frequency
        if isUnified {
            let nextDate = calculateNextContactDate(for: frequency)
            people = people.map {
                Friend(id: $0.id, name: $0.name, image: $0.image, source: $0.source, frequency: frequency, nextContactAt: nextDate)
            }
        }
    }
    
    // RegisterViewModel에서 선택한 연락처 받아오는 메소드
    func setPeople(from contacts: [Friend]) {
        self.people = contacts.map {
            Friend(id: $0.id, name: $0.name, image: $0.image, source: $0.source, frequency: $0.frequency)
        }
    }
    
    /// 카카오 이미지 다운로드
    func downloadKakaoImageData(completion: @escaping ([Friend]) -> Void) {
        var updatedPeople = people
        let group = DispatchGroup()
        
        for (index, friend) in people
            .enumerated() where friend.source == .kakao {
            guard let urlString = friend.imageURL else { continue }
            group.enter()
            
            SnsAuthService.shared.downloadImageData(from: urlString) { data in
                if let data = data, let image = UIImage(data: data) {
                    updatedPeople[index].image = image
                    print("🟢 [ContactFrequencySettingsViewModel] \(friend.name) 이미지 다운로드 성공")
                } else {
                    print("🔴 [ContactFrequencySettingsViewModel] \(friend.name) 이미지 다운로드 실패")
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.people = updatedPeople
            completion(updatedPeople)
        }
    }
    
    func uploadAllFriendsToServer(_ friends: [Friend]) {
        guard let accessToken = UserSession.shared.user?.serverAccessToken else { return }
        
        BackEndAuthService.shared.sendInitialFriends(friends: friends, accessToken: accessToken) { result in
            switch result {
            case .success(let registeredFriends):
                for friendWithURL in registeredFriends {
                    if let url = friendWithURL.preSignedImageUrl,
                       let localFriend = friends.first(where: { $0.name == friendWithURL.name }),
                       let image = localFriend.image?.jpegData(compressionQuality: 0.8) {
                        
                        BackEndAuthService.shared.uploadImageWithPresignedURL(imageData: image, presignedURL: url, contentType: "image/jpeg") { success in
                            print("▶️ \(friendWithURL.name)의 이미지 업로드: \(success ? "성공" : "실패")")
                        }
                    }
                }
            case .failure(let error):
                print("🔴 [ContactFrequencySettingsViewModel] 친구 등록 실패: \(error)")
            }
        }
    }
}
