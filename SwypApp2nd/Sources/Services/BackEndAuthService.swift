import Alamofire
import Foundation

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshTokenInfo: RefreshTokenInfo
}

struct RefreshTokenInfo: Decodable {
    let token: String
    let expiresAt: String
}

struct PresignedURLRequest: Encodable {
    let fileName: String
    let contentType: String
    let fileSize: Int
    let category: String
}

struct PresignedURLResponse: Decodable {
    let preSignedUrl: String
}

struct MemberMeInfoResponse: Decodable {
    let memberId: String
    let username: String
    let nickname: String
    let imageUrl: String?
    let averageRate: Int
    let isActive: Bool
    let marketingAgreedAt: String?
    let providerType: String
}

final class BackEndAuthService {
    static let shared = BackEndAuthService()

    private let baseURL: String = {
        if let host = Bundle.main.infoDictionary?["DEV_BASE_URL"] as? String {
            return "https://\(host)"
        } else {
            return ""
        }
    }()
    
    /// 백엔드: fetch User Data
    func fetchMemberInfo(accessToken: String, completion: @escaping (Result<MemberMeInfoResponse, Error>) -> Void) {
        let url = "\(baseURL)/member/me"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
            
        AF.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: MemberMeInfoResponse.self) { response in
                switch response.result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

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
                    print("\(Bundle.main.infoDictionary?["DEV_BASE_URL"] as? String ?? "")")
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
    
    /// 백엔드: PresignedURL 요청
    func requestPresignedURL(
        fileName: String,
        contentType: String,
        fileSize: Int,
        category: String,
        accessToken: String,
        completion: @escaping (String?) -> Void
    ) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        let body = PresignedURLRequest(
            fileName: fileName,
            contentType: contentType,
            fileSize: fileSize,
            category: category
        )
        
        AF.request(baseURL,
                   method: .post,
                   parameters: body,
                   encoder: JSONParameterEncoder.default,
                   headers: headers)
        .validate()
        .responseDecodable(of: PresignedURLResponse.self) { response in
            switch response.result {
            case .success(let result):
                print("🟢 [BackEndAuthService] presigned url 생성됨: \(result.preSignedUrl)")
                completion(result.preSignedUrl)
            case .failure(let error):
                print("🔴 [BackEndAuthService] presigned url 요청 실패: \(error)")
                completion(nil)
            }
        }
    }
    
    /// 백엔드: PresignedURL 사용 이미지 업로드
    func uploadImageWithPresignedURL(
        imageData: Data,
        presignedURL: String,
        contentType: String = "image/jpeg",
        completion: @escaping (Bool) -> Void
    ) {
        guard let url = URL(string: presignedURL) else {
            print("🔴 [BackEndAuthService] 유효하지 않은 Presigned URL")
            completion(false)
            return
        }

        AF.upload(imageData, to: url, method: .put, headers: [
            "Content-Type": contentType
        ])
        .validate(statusCode: 200..<300)
        .response { response in
            if let error = response.error {
                print("🔴 [BackEndAuthService] 업로드 실패: \(error.localizedDescription)")
                completion(false)
            } else {
                print("🟢 [BackEndAuthService] 업로드 성공 응답: \(response.response?.statusCode ?? 0)")
                completion(true)
            }
        }
    }
    
    /// 백엔드: 연락처에서 가져온 친구 목록 서버에 전달
    func sendInitialFriends(
        friends: [Friend],
        accessToken: String,
        completion: @escaping (Result<[FriendWithUploadURL], Error>) -> Void
    ) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
            
        let payload = FriendInitRequestDTO(
            friendList: friends.compactMap { $0.toInitRequestDTO()
            })
            
        let url = "\(baseURL)/friend/init"
            
        AF.request(
            url,
            method: .post,
            parameters: payload,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate()
        .responseDecodable(of: FriendInitResponseDTO.self) { response in
            switch response.result {
            case .success(let result):
                print("🟢 [BackEndAuthService] 친구 등록 성공! \(result.friendList.count)명")
                completion(.success(result.friendList))
            case .failure(let error):
                print("🔴 [BackEndAuthService] 친구 등록 실패: \(error)")
                completion(.failure(error))
            }
        }
    }
}
