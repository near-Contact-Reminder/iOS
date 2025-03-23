import Foundation

struct User: Codable, Identifiable {
    var id: String // 유저 고유 ID
    var name: String // 이름
    var email: String? // 이메일
    var profileImageURL: String? // 프로필 사진 URL
    var loginType: LoginType // 애플, 카카오
}

enum LoginType: String, Codable {
    case apple
    case kakao
}

