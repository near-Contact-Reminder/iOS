import Foundation
import UIKit
import KakaoSDKTalk
import KakaoSDKFriend
import KakaoSDKUser
import KakaoSDKCommon
import KakaoSDKAuth
import Combine
import Contacts

enum RegisterFriendsAlert: Identifiable {
    case limitExceeded(total: Int) // 전체 10명 초과
    case phoneSelectionExceeded// 선택 가능한 슬롯 초과
    case permissionDenied// 연락처 권한 OFF
    
    var id: String {
        switch self {
        case .limitExceeded:
            return "limitExceeded"
        case .phoneSelectionExceeded:
            return "phoneSelectionExceeded"
        case .permissionDenied:
            return "permissionDenied"
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

class RegisterFriendsViewModel: ObservableObject {
    @Published var selectedContacts: [Friend] = []
    @Published var activeAlert: RegisterFriendsAlert? = nil
    
    private let contactStore = CNContactStore()
    
    var canProceed: Bool {
        !selectedContacts.isEmpty
    }

    func removeContact(_ contact: Friend) {
        selectedContacts.removeAll { $0 == contact }
    }
    
    var phoneContacts: [Friend] {
        selectedContacts.filter { $0.source == .phone }
    }
    
    // MARK: - 애플 연락처 연동
    func requestContactsPermission(completion: @escaping (Bool) -> Void) {
        let status = CNContactStore.authorizationStatus(for: .contacts)

        switch status {
        case .notDetermined:
            contactStore.requestAccess(for: .contacts) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }

        case .authorized:
            completion(true)

        case .denied, .restricted:
            completion(false)

        case .limited:
            completion(true)
        @unknown default:
            completion(false)
        }
    }
    
    func handleSelectedContacts(_ contacts: [CNContact]) {
        let converted: [Friend] = contacts.compactMap {
            let name = $0.familyName + " " + $0.givenName
            let image = $0.thumbnailImageData.flatMap { UIImage(data: $0) }
            let birthDay = $0.birthday?.date
            let anniversaryDateComponents = $0.dates.first?.value as? DateComponents
            let anniversaryDay = anniversaryDateComponents?.date
            let anniversaryDayTitle = $0.dates.first?.label
            let anniversary: AnniversaryModel? = {
                guard let date = anniversaryDay else { return nil }
                guard var title = anniversaryDayTitle else { return nil }
                if title == "_$!<Anniversary>!$_" || title.isEmpty {
                    title =  "기념일"
                } else {
                    title = title
                }
                
                return AnniversaryModel(title: title, Date: date)
            }()
            let relationship = $0.contactRelations.first?.label
            
            let phoneNumber =  $0.phoneNumbers.first?.value.stringValue
            let memo = $0.note
            return Friend(
                        id: UUID(),
                        name: name,
                        image: image,
                        imageURL: nil,
                        source: .phone,
                        frequency: CheckInFrequency.none,
                        remindCategory: nil,
                        phoneNumber: phoneNumber,
                        relationship: relationship,
                        birthDay: birthDay,
                        anniversary: anniversary,
                        memo: memo,
                        nextContactAt: nil,
                        lastContactAt: nil,
                        checkRate: nil,
                        position: nil
                    )
        }
        print("🟢 [RegisterFriendsViewModel]\(String(describing: converted.first?.name))의 id: \(String(describing: converted.first?.id))")
        
        // 기존 등록된 친구 목록
        let existingFriends = UserSession.shared.user?.friends ?? []
        let existingIds = Set(existingFriends.map { $0.id })

        // 이미 선택한 전화 연락처
        let existingPhone = self.phoneContacts
        // 새로 추가될 연락처: 기존 등록된 친구들과 겹치지 않는 것만
        let newContacts = converted.filter { !existingIds.contains($0.id) }

        // 전체 등록될 수 있는 수 계산: 기존 등록된 친구 + 기존 전화 연락처 + 새로 선택한 연락처
        let potentialTotal = existingFriends.count + existingPhone.count + newContacts.count
        if potentialTotal > 10 {
            DispatchQueue.main.async {
                self.activeAlert = .limitExceeded(total: potentialTotal)
            }
            print("🟢 [RegisterFriendsViewModel] 최대 10명까지만 등록할 수 있어요. alert 발생")
            return
        }

        // 남은 전화 연락처 선택 가능 수
        let remainingPhone = max(0, 10 - existingPhone.count)
        // 새로 선택한 연락처 중 남은 수만큼만 사용
        if newContacts.count > remainingPhone {
            DispatchQueue.main.async {
                self.activeAlert = .phoneSelectionExceeded
            }
            print("🟢 [RegisterFriendsViewModel] 연락처는 최대 10명까지만 선택할 수 있어요. alert 발생")
            return
        }
        let limited = Array(newContacts.prefix(remainingPhone))

        // 기존 전화 연락처와 새로 선택한 연락처를 합쳐 중복을 제거한 후 적용
        let updatedPhone = existingPhone + limited
        self.selectedContacts = Array(Set(updatedPhone))
    }
}
