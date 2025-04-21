import Foundation
import UIKit
import KakaoSDKTalk
import KakaoSDKFriend
import KakaoSDKUser
import KakaoSDKCommon
import KakaoSDKAuth
import Combine
import Contacts

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

class RegisterFriendsViewModel: ObservableObject {
    @Published var selectedContacts: [Friend] = []
    @Published var alertItem: AlertItem? = nil // 10명 넘을시 alert
    
    private let contactStore = CNContactStore()
    
    var canProceed: Bool {
        !selectedContacts.isEmpty
    }

    func addContact(_ contact: Friend) {
        guard selectedContacts.count < 10 else { return }
        guard !selectedContacts.contains(contact) else { return }
        selectedContacts.append(contact)
    }

    func removeContact(_ contact: Friend) {
        selectedContacts.removeAll { $0 == contact }
    }
    
    var phoneContacts: [Friend] {
        selectedContacts.filter { $0.source == .phone }
    }

    var kakaoContacts: [Friend] {
        selectedContacts.filter { $0.source == .kakao }
    }
    
    // MARK: - 애플 연락처 연동
    func fetchContactsFromPhone(_ contacts: [CNContact]) {
        // 1. 권한 요청
        contactStore
            .requestAccess(for: .contacts) { granted, error in
                guard granted, error == nil else {
                    print("🔴 [RegisterFriendsViewModel] 연락처 접근 거부됨 또는 오류: \(String(describing: error))")
                    return
                }
                self.handleSelectedContacts(contacts)
            }
    }
    
    func handleSelectedContacts(_ contacts: [CNContact]) {
        let converted: [Friend] = contacts.compactMap {
            let name = $0.familyName + $0.givenName
            let image = $0.thumbnailImageData.flatMap { UIImage(data: $0) }
            let birthDay = $0.birthday?.date
            let anniversaryDay = $0.dates.first?.value as? Date
            let anniversaryDayTitle = $0.dates.first?.label
            let relationship = $0.contactRelations.first?.label
            
            let phoneNumber =  $0.phoneNumbers.first?.value.stringValue
//            let memo = $0.note
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
                        anniversary: AnniversaryModel(
                            title: anniversaryDayTitle ?? nil,
                            Date: anniversaryDay ?? nil),
//                        memo: memo,
                        nextContactAt: nil,
                        lastContactAt: nil,
                        checkRate: nil,
                        position: nil
                    )
        }
        print("🟢 [RegisterFriendsViewModel]\(String(describing: converted.first?.name))의 id: \(String(describing: converted.first?.id))")
        
        DispatchQueue.main.async {
            let existingFriends = UserSession.shared.user?.friends ?? []
            let existingIds = Set(existingFriends.map { $0.id })
            
            let totalCount = self.selectedContacts.count + existingFriends.count
            if totalCount > 10 {
                self.alertItem = AlertItem(message: "최대 10명까지만 등록할 수 있어요.")
                return
            }

            let newContacts = converted.filter { !existingIds.contains($0.id) }
            let remainingPhone = max(0, 5 - self.phoneContacts.count)
            let limited = Array(newContacts.prefix(remainingPhone))
            
            if newContacts.count > remainingPhone {
                self.alertItem = AlertItem(message: "연락처는 최대 5명까지만 선택할 수 있어요.")
                return
            }
            
            let existingKakao = self.selectedContacts.filter { $0.source == .kakao }
            self.selectedContacts = Array(Set(existingKakao + limited))

            print("🟢 등록된 연락처 수: \(self.phoneContacts.count) / 5")
        }
        print("🟢 [RegisterFriendsViewModel] 연락처 가져옴: \(self.selectedContacts)")
    }
    
    // MARK: - kakao 연락처 연동
    func fetchContactsFromKakao() {
        // MARK: - Test
        // Kakao 토큰이 없으면 로그인 연동 먼저 진행
        
        // 1. 카카오 로그인 (애플 로그인시에 카카오톡 로그인만 해서 친구 데이터만 가져오기)
        // 2. 토큰 관리..? -> 애플로그인이 진행됐으니 토큰은 필요없나,, 카카오 서버 토큰은 필요할듯
        // 3. 카카오 친구목록 호출
        print("🟡 [RegisterFriendsViewModel] fetchContactsFromKakao 호출됨")
        
        if let path = Bundle.main.path(forResource: "KakaoSDKFriendResources", ofType: "bundle") {
            print("KakaoSDKFriendResources.bundle 포함됨: \(path)")
        } else {
            print("KakaoSDKFriendResources.bundle 미포함")
        }
        
        if TokenManager.shared.get(for: .kakao) != nil {
            print("🟢 [RegisterFriendsViewModel] 기존 Kakao 토큰 있음 → 친구목록 요청")
            self.requestKakaoFriends()
        } else {
            print("🟡 [RegisterFriendsViewModel] Kakao 토큰 없음 → 로그인 시도")
            SnsAuthService.shared.loginWithKakao { oauthToken in
                guard let token = oauthToken else {
                    print("🔴 [RegisterFriendsViewModel] 카카오 로그인 실패")
                    return
                }

                TokenManager.shared.save(token: token.accessToken, for: .kakao)
                TokenManager.shared
                    .save(token: token.refreshToken, for: .kakao, isRefresh: true)

                print("🟢 [RegisterFriendsViewModel] 카카오 로그인 성공 → 친구목록 요청")
                self.requestKakaoFriends()
            }
        }
    }
    
    func requestKakaoFriends() {
        print("requestKakaoFriends 호출됨")
        // TODO: - Kakao비즈니스, 권한 신청 해야함
        // Kakao 친구 API 호출
        let openPickerFriendRequestParams = OpenPickerFriendRequestParams(
            title: "멀티 피커", // 피커 이름
            viewAppearance: .auto, // 피커 화면 모드
            orientation: .auto, // 피커 화면 방향
            enableSearch: false, // 검색 기능 사용 여부
            enableIndex: false, // 인덱스뷰 사용 여부
            showMyProfile: false, // 내 프로필 표시
            showFavorite: true, // 즐겨찾기 친구 표시 여부
            showPickedFriend: true, // 선택한 친구 표시 여부, 멀티 피커에만 사용 가능
            maxPickableCount: 5, // 선택 가능한 최대 대상 수
            minPickableCount: 1 // 선택 가능한 최소 대상 수
        )
        PickerApi.shared.selectFriendsPopup(params: openPickerFriendRequestParams) {
 selectedUsers,
 error in
            
            // TODO: - 탈퇴후 테스트 필요
            if let error = error as? SdkError,
               case .ApiFailed(_, _) = error,
               error.localizedDescription.contains("scope") {
                print("🔴 친구목록 권한 미동의 → scope 재요청")

                UserApi.shared
                    .loginWithKakaoAccount(scopes: ["friends"]) { _, error in
                        if let error = error {
                            print("🔴 friends scope 동의 실패: \(error)")
                        } else {
                            print("🟢 friends scope 동의 성공 → 친구목록 재요청")
                            self.requestKakaoFriends()
                        }
                    }
                return
            }

            if let error = error {
                print("🔴 친구 피커 오류: \(error)")
                return
            }

            guard let selectedUsers = selectedUsers?.users else {
                print("🟡 선택된 친구 없음")
                return
            }

            print("✅ 친구 선택 성공: \(selectedUsers)")
                
            // TODO: - 썸네일 이미지 URL → Signed URL 적용
            let kakaoContacts: [Friend] = selectedUsers.compactMap {
                let id = UUID()
                return Friend(
                    id: id,
                    name: $0.profileNickname ?? "이름 없음",
                    imageURL: $0.profileThumbnailImage?.absoluteString,
                    source: .kakao,
                    frequency: CheckInFrequency.none,
                    relationship: "",  //TODO : 이렇게가 맞나
                    fileName: "\(id.uuidString).jpg"
                )
            }
            DispatchQueue.main.async {
                let existingFriends = UserSession.shared.user?.friends ?? []
                let existingIds = Set(existingFriends.map { $0.id })

                let totalCount = self.selectedContacts.count + existingFriends.count
                if totalCount > 10 {
                    self.alertItem = AlertItem(message: "최대 10명까지만 등록할 수 있어요.")
                    return
                }
                
                let newKakaoContacts = kakaoContacts.filter {
                    !existingIds.contains($0.id)
                }

                let remainingKakao = max(0, 5 - self.kakaoContacts.count)
                let limited = Array(newKakaoContacts.prefix(remainingKakao))

                let existingPhone = self.selectedContacts.filter {
                    $0.source == .phone
                }
                self.selectedContacts = Array(Set(existingPhone + limited))

                print("🟢 등록된 카카오 친구 수: \(self.kakaoContacts.count) / 5")
            }
            
        }
    }
}
