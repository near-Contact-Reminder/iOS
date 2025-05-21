import Foundation

struct User: Codable, Identifiable {
    var id: String  // 유저 고유 ID
    var name: String  // 이름
    var email: String?  // 이메일
    var profileImageURL: String?  // 프로필 사진 URL
    var friends: [Friend] // 챙길 친구들
    var checkRate: Int? // 체크율
    var loginType: LoginType  // 애플, 카카오
    let serverAccessToken: String // 서버 access token
    let serverRefreshToken: String // 서버 refresh token
}

enum LoginType: String, Codable {
    case apple
    case kakao
}
