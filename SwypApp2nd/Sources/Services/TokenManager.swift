import Foundation

enum TokenType {
    case kakao, apple, server
}

final class TokenManager {
    static let shared = TokenManager()
    private let defaults = UserDefaults.standard

    private func key(for type: TokenType, isRefresh: Bool = false) -> String {
        switch type {
        case .kakao:
            return isRefresh ? "kakaoRefreshToken" : "kakaoAccessToken"
        case .apple:
            return "appleIdentityToken"
        case .server:
            return isRefresh ? "serverRefreshToken" : "serverAccessToken"
        }
    }

    func save(token: String, for type: TokenType, isRefresh: Bool = false) {
        defaults.set(token, forKey: key(for: type, isRefresh: isRefresh))
    }

    func get(for type: TokenType, isRefresh: Bool = false) -> String? {
        defaults.string(forKey: key(for: type, isRefresh: isRefresh))
    }

    func clear(type: TokenType) {
        defaults.removeObject(forKey: key(for: type, isRefresh: false))
        if type != .apple {
            defaults.removeObject(forKey: key(for: type, isRefresh: true))
        }
    }
}
