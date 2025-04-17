import Foundation
import UIKit
import Combine

class HomeViewModel: ObservableObject {
    @Published var peoples: [Friend] = []
    /// 내 사람들
    @Published var allFriends: [Friend] = []
    /// 이번달 챙길 사람
    @Published var thisMonthFriends: [Friend] = []
    
//    init() {
//        loadPeoplesFromUserSession()
//    }
//
//    func loadPeoplesFromUserSession() {
//        DispatchQueue.main.async {
//            self.peoples = UserSession.shared.user?.friends ?? []
//        }
//    }
    
    func fetchAndSetImage(for friend: Friend, accessToken: String, completion: @escaping (UIImage?) -> Void) {
        let fileName = "\(friend.id).jpg"
        let category = "Friends/profile"
        
        BackEndAuthService.shared.fetchPresignedDownloadURL(fileName: fileName, category: category, accessToken: accessToken) { url in
            guard let url = url else {
                completion(nil)
                return
            }

            self.downloadImage(from: url) { image in
                completion(image)
            }
        }
    }
    
    // PresignedURL 사용 이미지 데이터 다운
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                print("🟢 [HomeViewModel] 이미지 다운로드 성공")
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                print("🔴 [HomeViewModel] 이미지 다운로드 실패: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    func loadFriendList() {
        guard let token = UserSession.shared.user?.serverAccessToken else { return }
        
        BackEndAuthService.shared.fetchFriendList(accessToken: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let friendList):
                    self.peoples = friendList.map {
                        Friend(
                            id: UUID(uuidString: $0.friendId) ?? UUID(),
                            name: $0.name,
                            imageURL: $0.imageUrl,
                            source: .kakao,
                            // TODO: - 서버에서 받는 source로 변경
//                            source: $0.source,
                            position: $0.position
                        )
                    }
                case .failure(let error):
                    print("🔴 친구 목록 API 실패: \(error)")
                }
            }
        }
    }
}
