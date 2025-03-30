import Alamofire

final class BackEndAuthService {
    static let shared = BackEndAuthService()

    private let baseURL = "서버 URL"

    /// 백엔드: 카카오 로그인 처리
    func loginWithKakao(accessToken: String, completion: @escaping (Result<User, Error>) -> Void) {
        // TODO: - Server api 확인후 변경
        let url = "\(baseURL)/login/kakao"
        let params = ["access_token": accessToken]

        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<500)
            .responseDecodable(of: User.self) { response in
                completion(response.result.mapError { $0 as Error }) // Alamofire의 response.result는 Result<Success, AFError> 타입이 completion 클로저는 Result<User, Error>
            }
    }

    /// 백엔드: 애플 로그인 처리
    func loginWithApple(userId: String, identityToken: String, completion: @escaping (Result<User, Error>) -> Void) {
        // TODO: - Server api 확인후 변경
        let url = "\(baseURL)/login/apple"
        let params = ["user_id": userId, "identity_token": identityToken]

        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<500)
            .responseDecodable(of: User.self) { response in
                completion(response.result.mapError { $0 as Error })
            }
    }

    /// 백엔드: access token 재발급
    func refreshAccessToken(refreshToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        // TODO: - Server api 확인후 변경
        let url = "\(baseURL)/auth/refresh"
        let params = ["refresh_token": refreshToken]

        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<500)
            .responseDecodable(of: TokenResponse.self) { response in
                switch response.result {
                case .success(let tokenResponse):
                    completion(.success(tokenResponse.accessToken))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
