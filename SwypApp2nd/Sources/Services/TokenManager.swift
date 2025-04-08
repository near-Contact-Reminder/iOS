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
        print("🟢 [TokenManager] 저장됨 → key: \(String(describing: key)), token: \(token.prefix(20))...")
    }

    func get(for type: TokenType, isRefresh: Bool = false) -> String? {
        defaults.string(forKey: key(for: type, isRefresh: isRefresh))
        
        let key = key(for: type, isRefresh: isRefresh)
        let token = defaults.string(forKey: key)
        if let token = token {
            print("🟢 [TokenManager] 가져옴 → key: \(key), token: \(token.prefix(20))...")
        } else {
            print("🔴 [TokenManager] 없음 → key: \(key)")
        }
        return token
    }

    func clear(type: TokenType) {
        let accessKey = key(for: type, isRefresh: false)
        let refreshKey = key(for: type, isRefresh: true)

        defaults.removeObject(forKey: accessKey)
        print("🟢 [TokenManager] 삭제됨 → key: \(accessKey)")

        if type != .apple {
            defaults.removeObject(forKey: refreshKey)
            print("🟢 [TokenManager] 삭제됨 → key: \(refreshKey)")
        }
    }
}
