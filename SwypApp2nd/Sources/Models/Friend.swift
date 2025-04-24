import Foundation
import UIKit
import CoreData
import Contacts

struct Friend: Identifiable, Equatable, Hashable, Codable {
    var id: UUID
    var name: String
    var image: UIImage?
    var imageURL: String?
    var source: ContactSource
    var frequency: CheckInFrequency?
    var remindCategory: RemindCategory?
    var phoneNumber: String?
    var relationship: String?// 관계
    var birthDay: Date? // 생일
    var anniversary: AnniversaryModel? // 기념일
    var memo: String? // 메모
    var nextContactAt: Date? // 다음 연락 예정일
    var lastContactAt: Date? // 마지막 연락 일
    var checkRate: Int? // 챙김률
    var position: Int? // 내사람들 리스트 순서
    var fileName: String? // 서버에서 받은 (friend.id).jpg
    var entity: PersonEntity?
    
    enum CodingKeys: String, CodingKey {
        case id, name, imageURL, source, frequency, remindCategory,
             relationship, birthDay, anniversary, memo,
             nextContactAt, lastContactAt, checkRate, position
    }
}

struct AnniversaryModel: Codable, Equatable, Hashable {
    var id: Int?
    var title: String?
    var Date: Date?
}

enum CheckInFrequency: String, CaseIterable, Identifiable, Codable {
    case none = "주기 선택"
    case daily = "매일"
    case weekly = "매주"
    case biweekly = "2주"
    case monthly = "매달"
    case semiAnnually = "6개월"
    
    var id: String { rawValue }
    
    init?(from dto: FriendDetailResponse.ContactFrequency?) {
        guard let dto = dto else {
            self = .none
            return
        }
        
        switch dto.contactWeek {
        case "EVERY_DAY": self = .daily
        case "EVERY_WEEK": self = .weekly
        case "EVERY_TWO_WEEK": self = .biweekly
        case "EVERY_MONTH": self = .monthly
        case "EVERY_SIX_MONTH": self = .semiAnnually
        default: self = .none
        }
    }
}

enum RemindCategory: Codable {
    case message
    case birth
    case anniversary
}

enum ContactSource: Codable {
    case phone, kakao
}

extension Friend {
    func toInitRequestDTO() -> FriendInitDTO? {
        // 필수 필드가 없으면 nil 반환
        guard let frequency = frequency,
              let nextDate = nextContactAt,
              let contactWeek = frequency.toContactWeek(),
              let sourceString = source.toServerValue()
        else {
            print("🔴 필수 값 누락: frequency=\(String(describing: frequency)), nextContactAt=\(String(describing: nextContactAt)), source=\(source)")
            return nil
        }
        
        print("🟢 toInitRequestDTO 변환 시작 for: \(name)")
        
        let dayOfWeek = nextDate.dayOfWeekString()

        // 이미지 업로드 정보가 필요한 경우에만 포함
        let imageUploadRequest: ImageUploadRequestDTO? = {
            guard let image = image,
                  let imageData = image.jpegData(compressionQuality: 0.4)
            else { return nil }
            
            let fileNameToUse = fileName ?? "\(id.uuidString).jpg"
            
            print("🟢 업로드된 이미지 파일 이름: \(fileNameToUse)")
            
            return ImageUploadRequestDTO(
                fileName: fileNameToUse,
                contentType: "image/jpeg",
                fileSize: imageData.count,
                category: "Friends/profile"
            )
        }()

        let anniversaryDTO: AnniversaryDTO? = {
            guard let anniversary = anniversary,
                  let title = anniversary.title,
                  let date = anniversary.Date
            else {
                print("🔴 [toInitRequestDTO] 기념일 정보 없음 - \(name)")
                return nil
            }

            let formatted = date.formattedYYYYMMDD()
            print("🟢 [toInitRequestDTO] \(name)의 기념일 DTO: \(title) / \(formatted)")
            // TODO: - 기념일 Array로 변경시 추후 수정 필요
            return AnniversaryDTO(title: title, date: formatted)
        }()
        
        let birthDayString = birthDay?.formattedYYYYMMDD()
        let relationship = relationship ?? "ACQUAINTANCE" // TODO FORCED

        
        print("""
        🧩 \(name)의 InitDTO 생성 요약
        - phone: \(phoneNumber ?? "없음")
        - memo: \(memo ?? "없음")
        - birthday: \(birthDayString ?? "없음")
        - relation(raw): \(relationship)
        - relation(mapped): \(mappedRelation(from: relationship))
        - anniversary: \(anniversaryDTO?.title ?? "없음") / \(anniversaryDTO?.date ?? "없음")
        """)
        
        return FriendInitDTO(
            name: name,
            source: sourceString,
            contactFrequency: ContactFrequencyDTO(
                contactWeek: contactWeek,
                dayOfWeek: dayOfWeek
            ),
            imageUploadRequest: imageUploadRequest,
            anniversary: anniversaryDTO,
            birthDay: birthDayString,
            relation: mappedRelation(from: relationship),
            memo: memo,
            phone: phoneNumber
        )
    }
    
    func mappedRelation(from label: String?) -> String {
        guard let label = label else { return "ACQUAINTANCE" }
        
        switch label {
        case CNLabelContactRelationFriend:
            return "FRIEND"
        case CNLabelContactRelationFather,
             CNLabelContactRelationMother,
             CNLabelContactRelationParent,
             CNLabelContactRelationSibling,
             CNLabelContactRelationChild:
            return "FAMILY"
        case CNLabelContactRelationPartner,
             CNLabelContactRelationSpouse:
            return "LOVER"
        case CNLabelContactRelationManager,
             CNLabelContactRelationAssistant:
            return "COLLEAGUE"
        default:
            return "ACQUAINTANCE"
        }
    }
}

extension ContactSource {
    init(serverValue: String) {
        switch serverValue.uppercased() {
        case "KAKAO": self = .kakao
        case "APPLE": self = .phone
        default:
            print("🔴 [ContactSource] 알 수 없는 값 '\(serverValue)', 기본값 .phone 사용")
            self = .phone
        }
    }
    func toServerValue() -> String? {
        switch self {
        case .phone: return "APPLE"
        case .kakao: return "KAKAO"
        }
    }
}

extension CheckInFrequency {
    func toContactWeek() -> String? {
        switch self {
        case .daily: return "EVERY_DAY"
        case .weekly: return "EVERY_WEEK"
        case .biweekly: return "EVERY_TWO_WEEK"
        case .monthly: return "EVERY_MONTH"
        case .semiAnnually: return "EVERY_SIX_MONTH"
        default: return nil
        }
    }
}

extension Date {
    func dayOfWeekString() -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)

        // 일요일 = 1, 토요일 = 7
        switch weekday {
        case 1: return "SUNDAY"
        case 2: return "MONDAY"
        case 3: return "TUESDAY"
        case 4: return "WEDNESDAY"
        case 5: return "THURSDAY"
        case 6: return "FRIDAY"
        case 7: return "SATURDAY"
        default: return "MONDAY"
        }
    }
}

extension ISO8601DateFormatter {
    func formatDateOnly(_ date: Date) -> String {
        self.formatOptions = [.withFullDate]
        return self.string(from: date)
    }
}

struct FriendInitRequestDTO: Codable {
    let friendList: [FriendInitDTO]
}

struct FriendInitDTO: Codable {
    let name: String
    let source: String
    let contactFrequency: ContactFrequencyDTO
    let imageUploadRequest: ImageUploadRequestDTO?
    let anniversary: AnniversaryDTO?
    let birthDay: String?
    let relation: String?
    let memo: String?
    let phone: String?
}

struct ContactFrequencyDTO: Codable {
    let contactWeek: String
    let dayOfWeek: String
}

struct ImageUploadRequestDTO: Codable {
    let fileName: String
    let contentType: String
    let fileSize: Int
    let category: String
}

struct AnniversaryDTO: Codable {
    let title: String
    let date: String
}

struct FriendInitResponseDTO: Codable {
    let friendList: [FriendWithUploadURL]
}

struct FriendWithUploadURL: Codable {
    let friendId: String
    let name: String
    let source: String
    let contactFrequency: ContactFrequencyDTO
    let phone: String?
    let nextContactAt: String?
    let preSignedImageUrl: String?
    let anniversary: FriendInitResponseAnniversary?
    let fileName: String?
}

struct FriendInitResponseAnniversary: Codable {
    let id: Int
    let title: String
    let date: String
}

extension Friend {
    func toPersonEntity(context: NSManagedObjectContext) -> PersonEntity {
        let entity = PersonEntity(context: context)
        entity.id = self.id
        entity.name = self.name
//        entity.imageURL = self.imageURL
//        entity.phoneNumber = self.phoneNumber
//        entity.relationship = self.relationship
//        entity.birthDay = self.birthDay
//        entity.anniversaryTitle = self.anniversary?.title
//        entity.anniversaryDate = self.anniversary?.Date
//        entity.memo = self.memo
//        entity.nextContactAt = self.nextContactAt
//        entity.lastContactAt = self.lastContactAt
        entity.reminderInterval = self.frequency?.rawValue
//        entity.position = Int64(self.position ?? 0)
        return entity
    }
}
