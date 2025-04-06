import Foundation
import KakaoSDKTalk
import KakaoSDKFriendCore
import Combine
import Contacts

struct Contact: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let source: ContactSource
}

enum ContactSource {
    case phone, kakao
}

class RegisterFriendsViewModel: ObservableObject {
    @Published var selectedContacts: [Contact] = []
    
    private let contactStore = CNContactStore()
    
    var canProceed: Bool {
        !selectedContacts.isEmpty
    }

    func addContact(_ contact: Contact) {
        guard selectedContacts.count < 10 else { return }
        guard !selectedContacts.contains(contact) else { return }
        selectedContacts.append(contact)
    }

    func removeContact(_ contact: Contact) {
        selectedContacts.removeAll { $0 == contact }
    }
    
    var phoneContacts: [Contact] {
        selectedContacts.filter { $0.source == .phone }
    }

    var kakaoContacts: [Contact] {
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
        let converted: [Contact] = contacts.compactMap {
            let name = $0.familyName + $0.givenName
            return Contact(id: UUID(), name: name, source: .phone)
        }

        let existingNonPhone = selectedContacts.filter { $0.source != .phone }
        let merged = existingNonPhone + converted
        let deduped = Array(Set(merged)).prefix(5)
        self.selectedContacts = Array(deduped)
        print("🟢 [RegisterFriendsViewModel] 연락처 가져옴: \(self.selectedContacts)")
    }
    
    // MARK: - kakao 연락처 연동
    func fetchContactsFromKakao() {
        // MARK: - Test
        print("fetchContactsFromKakao 호출됨")
        // Kakao 토큰이 없으면 로그인 연동 먼저 진행
        
        // 1. 카카오 로그인
        // 2. 토큰 관리..? -> 애플로그인이 진행됐으니 토큰은 필요없나,, 카카오 서버 토큰은 필요할듯
        // 3. 카카오 친구목록 호출
        guard TokenManager.shared.get(for: .kakao) != nil else {
            print("🟡 [RegisterFriendsViewModel] 애플 유저 - 카카오 로그인 먼저 필요")
            SnsAuthService.shared.loginWithKakao { [weak self] token in
                guard let token = token else {
                    print("🔴 [RegisterFriendsViewModel] 카카오 로그인 실패")
                    return
                }
                
                print("🟢 [RegisterFriendsViewModel] 카카오 로그인 성공")

                TokenManager.shared.save(token: token.accessToken, for: .kakao)
                TokenManager.shared
                    .save(
                        token: token.refreshToken,
                        for: .kakao,
                        isRefresh: true
                    )

                self?.requestKakaoFriends()
            }
            return
        }
    }
    
    func requestKakaoFriends() {
        print("requestKakaoFriends 호출됨")
        // TODO: - Kakao비즈니스, 권한 신청 해야함
        // Kakao 친구 API 호출
//        let openPickerFriendRequestParams = OpenPickerFriendRequestParams(
//            title: "멀티 피커", // 피커 이름
//            viewAppearance: .auto, // 피커 화면 모드
//            orientation: .auto, // 피커 화면 방향
//            enableSearch: true, // 검색 기능 사용 여부
//            enableIndex: true, // 인덱스뷰 사용 여부
//            showFavorite: true, // 즐겨찾기 친구 표시 여부
//            showPickedFriend: true, // 선택한 친구 표시 여부, 멀티 피커에만 사용 가능
//            maxPickableCount: 5, // 선택 가능한 최대 대상 수
//            minPickableCount: 1 // 선택 가능한 최소 대상 수
//        )
//        PickerApi.shared.selectFriendsPopup(params: openPickerFriendRequestParams) { selectedUsers, error in
//            if let error = error {
//                print(error)
//            }
//            else {
//                print("selectFriendsPopup(params:) success.")
//                
//                // 성공 시 동작 구현
//                _ = selectedUsers
//            }
//        }
    }
}
