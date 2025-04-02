import Alamofire

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshTokenInfo: RefreshTokenInfo
}

struct RefreshTokenInfo: Decodable {
    let token: String
    let expiresAt: String
}

final class BackEndAuthService {
    static let shared = BackEndAuthService()

    private let baseURL = "https://dev.near.io.kr"

    /// 백엔드: 카카오 로그인 처리
    func loginWithKakao(accessToken: String, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        let url = "\(baseURL)/auth/social"
        let params = ["accessToken": accessToken,
                      "providerType": "KAKAO"]

        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: TokenResponse.self) { response in
                switch response.result {
                case .success(let tokenResponse):
                    print(
                        "🟢 [BackEndAuthService] 카카오 로그인 성공 - accessToken: \(tokenResponse.accessToken.prefix(10))..., refreshToken: \(tokenResponse.refreshTokenInfo.token.prefix(10))..."
                    )
                    completion(.success(tokenResponse))
                case .failure(let error):
                    print(
                        "🔴 [BackEndAuthService] 카카오 로그인 실패: \(error.localizedDescription)"
                    )
                    completion(.failure(error))
                }
            }
    }

    /// 백엔드: 애플 로그인 처리
    func loginWithApple(userId: String, identityToken: String, authorizationCode: String, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        let url = "\(baseURL)/auth/social"
        let params = [
            "identityToken": identityToken,
            "authorizationCode": authorizationCode,
            "providerType": "APPLE"
        ]

        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: TokenResponse.self) { response in
                switch response.result {
                case .success(let tokenResponse):
                    print(
                        "🟢 [BackEndAuthService] 애플 로그인 성공 - accessToken: \(tokenResponse.accessToken.prefix(10))..., refreshToken: \(tokenResponse.refreshTokenInfo.token.prefix(10))..."
                    )
                    completion(.success(tokenResponse))
                case .failure(let error):
                    print(
                        // TODO: - AppleLogin은 실패중...
                        "🔴 [BackEndAuthService] 애플 로그인 실패: \(error.localizedDescription)"
                    )
                    completion(.failure(error))
                }
            }
    }

    /// 백엔드: access token 재발급
    func refreshAccessToken(refreshToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        // TODO: - Server api 확인후 변경
        let url = "\(baseURL)/auth/renew"
        let params = ["refreshToken": refreshToken]

        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: TokenResponse.self) { response in
                switch response.result {
                case .success(let tokenResponse):
                    print("🟢 [BackEndAuthService] access token 재발급 성공 - newAccessToken: \(tokenResponse.accessToken.prefix(10))...")
                    completion(.success(tokenResponse.accessToken))
                case .failure(let error):
                    print("🔴 [BackEndAuthService] access token 재발급 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }
}
