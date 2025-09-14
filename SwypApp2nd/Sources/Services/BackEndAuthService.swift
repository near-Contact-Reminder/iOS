import Alamofire
import Foundation

// MARK: - 서버 토큰 관리
struct TokenResponse: Decodable {
    let accessToken: String
    let refreshTokenInfo: RefreshTokenInfo
}

struct RefreshTokenInfo: Decodable {
    let token: String
    let expiresAt: String
}

// MARK: - PreSignedURL
struct PresignedURLRequest: Encodable {
    let fileName: String
    let contentType: String
    let fileSize: Int
    let category: String
}

struct PresignedURLResponse: Decodable {
    let preSignedUrl: String
}

// MARK: - 엑세스 토큰으로 회원 정보 조회
struct MemberMeInfoResponse: Decodable {
    let memberId: String
    let username: String
    let nickname: String
    let imageUrl: String?
    let marketingAgreedAt: String?
    let providerType: String
}

// MARK: - 친구 리스트 조회
struct FriendListResponse: Codable, Identifiable {
    let friendId: String
    let position: Int
    let name: String
    let imageUrl: String?
    let source: String?
    let fileName: String?
    let lastContactAt: String?
    let checkRate: Int?

    var id: String { friendId }
}

// MARK: - 회원 탈퇴
struct WithdrawRequest: Encodable {
    let reasonType: String
    let customReason: String
}

// MARK: - 친구 상세 정보 조회
struct FriendDetail {
    let friendId: String
    let imageUrl: String?
    let relation: String?
    let contactFrequency: CheckInFrequency?
    let birthDay: String?
    let anniversaryList: [AnniversaryModel]?
    let memo: String?
    let phone: String?

    struct AnniversaryList {
        let id : String
        let title: String
        let date: String
    }

    struct ContactFrequency {
        let contactWeek : String
        let dayOfWeek : String
    }
}

struct FriendDetailResponse: Codable {
    let friendId: String
    let imageUrl: String?
    let relation: String?
    let name: String
    let contactFrequency: FriendDetailResponse.ContactFrequency?
    let birthday: String?
    let anniversaryList: [FriendDetailResponse.AnniversaryResponse]?
    let memo: String?
    let phone: String?

    struct ContactFrequency: Codable {
        let contactWeek: String
        let dayOfWeek: String
    }

    struct AnniversaryResponse: Codable {
        let id: Int
        let title: String
        let date: String
    }
}

// MARK: - 친구 챙김 로그 리스트
struct CheckInRecord: Identifiable, Codable {
    var id: UUID = UUID()
    let isChecked: Bool
    let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case isChecked
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isChecked = try c.decode(Bool.self, forKey: .isChecked)

        // 오프셋 없는 "yyyy-MM-dd HH:mm:ss"
        let str = try c.decode(String.self, forKey: .createdAt)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")!
        guard let d = f.date(from: str) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: c,
                    debugDescription: "Unrecognized date format")
        }
        createdAt = d
    }

    init(isChecked: Bool, createdAt: Date) {
        self.isChecked = isChecked
        self.createdAt = createdAt
        self.id = UUID()
    }
}

// MARK: - 챙김 버튼
struct RecordButtonResponse: Codable {
    let message: String
}

// MARK: - 친구 상세 정보 업데이트
struct FriendUpdateRequestDTO: Codable {
    let name: String
    let relation: String?
    let contactFrequency: ContactFrequencyDTO?
    let birthday: String?
    let anniversaryList: [FriendUpdateRequestAnniversaryDTO]?
    let memo: String?
    let phone: String?
}

struct FriendUpdateRequestAnniversaryDTO: Codable {
    var id: Int?
    var title: String?
    var date: String?
}

// MARK: - 이번달 챙길 친구
struct FriendMonthlyResponse: Codable {
    var friendId: String
    var name: String
    var type: String
    var nextContactAt: String
}

// MARK: - 친구 순서 변경
struct FriendOrderUpdateRequestDTO: Codable {
    let newPosition: Int
}

// MARK: - 체크율
struct FriendCheckRateRespose: Codable {
    var checkRate: Int
}


// MARK: - 서버 통신 로직
final class BackEndAuthService {
    static let shared = BackEndAuthService()

    private let baseURL: String = {
    #if DEBUG
        if let host = Bundle.main.infoDictionary?["DEV_BASE_URL"] as? String {
            return "https://\(host)"
        }
    #else
        if let host = Bundle.main.infoDictionary?["RELEASE_BASE_URL"] as? String {
            return "https://\(host)"
        }
    #endif
        return ""
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
    
    /// 백엔드: Presigned Download URL 발급 받기
    func fetchPresignedDownloadURL(
        fileName: String,
        category: String,
        accessToken: String,
        completion: @escaping (URL?) -> Void
    ) {
        let url = "\(baseURL)/s3"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        let params = [
            "fileName": fileName,
            "category": category
        ]

        AF.request(url, method: .get, parameters: params, headers: headers)
            .validate()
            .responseDecodable(of: PresignedURLResponse.self) { response in
                switch response.result {
                case .success(let data):
                    print("🟢 [BackEndAuthService] Presigned 다운로드 URL 생성됨")
                    completion(URL(string: data.preSignedUrl))
                case .failure(let error):
                    print("🔴 [BackEndAuthService] 다운로드 URL 요청 실패: \(error.localizedDescription)")
                    completion(nil)
                }
            }
    }

    func startMigration(accessToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        let url = "\(baseURL)/alarm/migration" // TODO Sep 1 앤드포인트가 없는데 왜 success가 뜨지

        AF.request(url, method: .post, headers: headers)
        .validate(statusCode: 200..<300)
        .response { response in
            switch response.result {
            case .success:
                print("🟢 [startMigration] 마이그레이션 성공")
                completion(.success(()))
            case .failure(let error):
                print("🔴 [startMigration] 마이그레이션 실패: \(error)")
                completion(.failure(error))
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
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(payload)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🟡 [sendInitialFriends] 서버에 보낸 요청 JSON:\n\(jsonString)")
            }
        } catch {
            print("🔴 [sendInitialFriends] 요청 JSON 인코딩 실패: \(error)")
        }
            
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
                print("🟢 [sendInitialFriends] 친구 등록 성공! \(result.friendList.count)명")
                
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    let jsonData = try encoder.encode(result.friendList)
                    if let jsonString = String(
                        data: jsonData,
                        encoding: .utf8
                    ) {
                        print("🟡 [sendInitialFriends] 서버 응답 JSON:\n\(jsonString)")
                    }
                } catch {
                    print("🔴 [sendInitialFriends] JSON 인코딩 실패: \(error)")
                }
                
                completion(.success(result.friendList))
            case .failure(let error):
                print("🔴 [sendInitialFriends] 친구 등록 실패: \(error)")
                completion(.failure(error))
            }
        }
    }

    // 백엔드: 리마인더 전송
    func sendReminder(friendId: UUID, accessToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = "\(baseURL)/friend/reminder/\(friendId.uuidString)"
        let headers : HTTPHeaders = ["Authorization":  "Bearer \(accessToken)"]
//        let params: Parameters = [ "friend-id": friendId.uuidString]

        AF.request(url, method: .post, headers: headers)
            .validate(statusCode: 200..<300)
            .response { response in
                switch response.result {
                case .success:
                    print("🟢 [BackEndAuthService] 리마인더 전송 성공")
                    completion(.success(()))
                case .failure(let error):
                    print("🔴 [BackEndAuthService] 리마인더 전송 실패: \(error.localizedDescription)")
                    completion(.failure(error))
            }
        }
    }
    
    func withdraw(accessToken: String, selectedReason: String, customReason:String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        let url = "\(baseURL)/member/withdraw"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        let body = WithdrawRequest(reasonType: selectedReason, customReason: customReason)
       
        AF.request(
            url,
            method: .delete,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    print("🟢 [BackEndAuthService] 탈퇴 전송 성공")
                    completion(.success(()))
                case .failure(let error):
                    print("🔴 [BackEndAuthService] 탈퇴 전송 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }
    
    /// 백엔드: 챙길 친구 리스트 조회
    func fetchFriendList(accessToken: String, completion: @escaping (Result<[FriendListResponse], Error>) -> Void) {
        let url = "\(baseURL)/friend/list"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]

        AF.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: [FriendListResponse].self) { response in

                if let data = response.data,
                   let jsonString = String(data: data, encoding: .utf8) {
                    print("🟡 [fetchFriendList] Raw response JSON:\n\(jsonString)")
                }
                
                switch response.result {
                case .success(let list):
                    print("🟢 [BackEndAuthService] 친구 리스트 조회 성공 \(list.map { $0.name })")
                    print("🟢 [BackEndAuthService] 친구 리스트 챙김률 조회 성공 \(list.map { $0.checkRate })")
                    completion(.success(list))
                case .failure(let error):
                    print("🔴 [BackEndAuthService] 친구 리스트 조회 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }
    
    /// 백엔드: 친구별 상세정보 조회
    func getFriendDetail(friendId: UUID, accessToken: String, completion: @escaping (Result<FriendDetail, Error>) -> Void) {
        print("🟡 [BackEndAuthService] 친구 상세정보 조회 요청됨 - friendId: \(friendId)")
        
        let url = "\(baseURL)/friend/\(friendId.uuidString)"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        AF.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: FriendDetailResponse.self) { response in
                switch response.result {
                case .success(let detail):
                    print(
                        "🟢 [BackEndAuthService] 친구별 상세정보 조회 성공 - \(detail.name)"
                    )
                    
                    do {
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                        let jsonData = try encoder.encode(detail)
                        if let jsonString = String(
                            data: jsonData,
                            encoding: .utf8
                        ) {
                            print("🟡 [getFriendDetail] 서버 응답 JSON:\n\(jsonString)")
                        }
                    } catch {
                        print("🔴 [getFriendDetail] JSON 인코딩 실패: \(error)")
                    }
                        
                    let friendDetail = FriendDetail(
                        friendId: detail.friendId,
                        imageUrl: detail.imageUrl,
                        relation: detail.relation?.uppercased(),
                        contactFrequency: CheckInFrequency(from: detail.contactFrequency),
                        birthDay: detail.birthday,
                        anniversaryList: detail.anniversaryList?.compactMap { $0 }.map {
                            AnniversaryModel(id: $0.id ,title: $0.title, Date: $0.date.toDate())
                        },
                        memo: detail.memo,
                        phone: detail.phone
                    )
                    completion(.success(friendDetail))
                case .failure(let error):
                    print(
                        "🔴 [BackEndAuthService] 친구별 상세정보 조회 실패: \(error.localizedDescription)"
                    )
                    completion(.failure(error))
                }
            }
    }
    
    /// 백엔드:친구 삭제
    func deletFriend(friendId: UUID, accessToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("🟡 [BackEndAuthService] 친구 삭제 요청됨 - friendId: \(friendId)")
        
        let url = "\(baseURL)/friend/\(friendId.uuidString)"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        AF.request(url, method: .delete, headers: headers)
            .validate(statusCode: 200..<300)
            .response{ response in
                switch response.result {
                case .success:
                    print("🟢 [BackEndAuthService] 친구 삭제 전송 성공")
                    completion(.success(()))
                case .failure(let error):
                    print("🔴 [BackEndAuthService] 친구 삭제 전송 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }
    
    /// 백엔드: 친구 상세 정보 업데이트
    func updateFriend(friendId: UUID, request: FriendUpdateRequestDTO, accessToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("🟡 [BackEndAuthService] 친구 상세 정보 업데이트 - friendId: \(friendId)")
        
        let url = "\(baseURL)/friend/\(friendId.uuidString)"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(request)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🟡 [updateFriend] 서버에 보낸 요청 JSON:\n\(jsonString)")
            }
        } catch {
            print("🔴 [updateFriend] 요청 JSON 인코딩 실패: \(error)")
        }
        
        AF.request(
                url,
                method: .put,
                parameters: request,
                encoder: JSONParameterEncoder.default,
                headers: headers
            )
            .validate(statusCode: 200..<300)
            .response{ response in
                switch response.result {
                case .success:
                    print("🟢 [BackEndAuthService] 친구 상세 정보 업데이트 성공")
                    completion(.success(()))
                case .failure(let error):
                    print("🔴 [BackEndAuthService] 친구 상세 정보 업데이트 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }
    
    /// 백엔드: 친구별 챙김 로그 리스트
    func getFriendRecords(friendId: UUID, accessToken: String, completion: @escaping (Result<[CheckInRecord], Error>) -> Void) {
        
        print("🟡 [BackEndAuthService] 친구 친구별 챙김 로그 리스트 조회 요청됨 - friendId: \(friendId)")
        
        let url = "\(baseURL)/friend/record/\(friendId.uuidString)"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        AF.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: [CheckInRecord].self) { response in
                switch response.result {
                case .success(let checkInRecords):
                    print(
                        "🟢 [BackEndAuthService] 친구별 챙김 로그 리스트 조회 성공 - \(checkInRecords)"
                    )
                    
                    completion(.success(checkInRecords))
                    
                case .failure(let error):
                    print(
                        "🔴 [BackEndAuthService] 친구별 챙김 로그 리스트 조회 실패: \(error.localizedDescription)"
                    )
                    completion(.failure(error))
                }
            }
    }
    
    /// 백엔드: 챙기기 버튼 클릭
    func postFriendCheck(friendId: UUID, accessToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = "\(baseURL)/friend/record/\(friendId.uuidString)"
            
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
            
        AF.request(url, method: .post, headers: headers)
            .validate()
            .responseDecodable(of: RecordButtonResponse.self) { response in
                switch response.result {
                case .success(let result):
                    completion(.success(result.message))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    /// 백엔드: 이번달 챙길 친구 조회
    func getMonthlyFriends(accessToken: String, completion: @escaping (Result<[FriendMonthlyResponse], Error>) -> Void) {
        let url = "\(baseURL)/friend/monthly"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        print("🟡 [BackEndAuthService] 이번달 친구 조회 요청")
        
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(
                of: [FriendMonthlyResponse].self
            ) { response in
                switch response.result {
                case .success(let monthlyFriends):
                    print(
                        "🟢 [BackEndAuthService] 이번달 친구 조회 성공 - \(monthlyFriends.map { $0.name })"
                    )
                    
                    completion(.success(monthlyFriends))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    /// 백엔드: 친구 순서 변경
    func patchFriendOrder(accessToken: String, id: String, newPosition: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = "\(baseURL)/friend/list/\(id)"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        let requestData = FriendOrderUpdateRequestDTO(newPosition: newPosition)
        
        AF.request(
            url,
            method: .patch,
            parameters: requestData,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate(statusCode: 200..<300)
        .response { response in
            switch response.result {
            case .success:
                print("🟢 [BackEndAuthService] 친구 순서 변경 성공 - id: \(id), newPosition: \(response.result)")
                completion(.success(()))
            case .failure(let error):
                print("🔴 [BackEndAuthService] 친구 순서 변경 실패 - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
    }
    
    
    /// 백엔드: (챙김 기록 기반) 체크율
    func getUserCheckRate(accessToken: String, completion: @escaping (Result<FriendCheckRateRespose, Error>) -> Void) {
        let url = "\(baseURL)/member/check-rate"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        AF.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: FriendCheckRateRespose.self) { response in
                switch response.result {
                case .success(let checkRate):
                    print("🟢 [BackEndAuthService] 친구 챙김율 조회 성공 - \(checkRate)")
                    completion(.success(checkRate))
                case .failure(let error):
                    print("🔴 [BackEndAuthService] 친구 챙김율율 조회 실패 - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }

    /// 유저의 전체 챙김률
    func getUserCheckRate(accessToken: String, completion: @escaping (Int) -> Void) {

        BackEndAuthService.shared
            .getUserCheckRate(accessToken: accessToken) { result in
                switch result {
                case .success(let success):
                    print(
                        "🟢 [UserSession] getUserCheckRate 성공 챙김률: \(success.checkRate)"
                    )
                    UserSession.shared.user?.checkRate = success.checkRate
                    completion(success.checkRate)
                case .failure(let error):
                    print("🔴 [UserSession] getUserCheckRate 실패: \(error)")
                    completion(0)
                }
            }
    }

    /// 백엔드: FCM 토큰 등록
    func registerFCMTokenToServer(token: String, accessToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = "\(baseURL)/messaging/register"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]

        let parameters = [
            "token": token,
            "osType": "IOS"
        ]

        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
        .validate(statusCode: 200..<300)
        .response { response in
            switch response.result {
            case .success:
                print("🟢 [BackEndAuthService] FCM 토큰 등록 성공")
                completion(.success(()))
            case .failure(let error):
            print("🔴 [BackEndAuthService] FCM 토큰 등록 실패: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
}


