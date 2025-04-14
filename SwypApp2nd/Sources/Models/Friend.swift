import Foundation
import UIKit

struct Friend: Identifiable, Equatable, Hashable, Codable {
    var id: UUID
    var name: String
    var image: UIImage?
    var imageURL: String?
    var source: ContactSource
    var frequency: CheckInFrequency?
    var remindCategory: RemindCategory?
    var phoneNumber: String?
    var relationship: String? // 관계
    var birthDay: Date? // 생일
    var anniversary: AnniversaryModel? // 기념일
    var memo: String? // 메모
    var nextContactAt: Date? // 다음 연락 예정일
    var lastContactAt: Date? // 마지막 연락 일
    var checkRate: Int? // 챙김률
    var position: Int? // 내사람들 리스트 순서
    
    enum CodingKeys: String, CodingKey {
        case id, name, imageURL, source, frequency, remindCategory,
             relationship, birthDay, anniversary, memo,
             nextContactAt, lastContactAt, checkRate, position
    }
}

struct AnniversaryModel: Codable, Equatable, Hashable {
    var title: String?
    var Date: Date?
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
                  let imageData = image.jpegData(compressionQuality: 0.8)
            else { return nil }

            return ImageUploadRequestDTO(
                fileName: "\(id).jpg",
                contentType: "image/jpeg",
                fileSize: imageData.count,
                category: "Friends/profile"
            )
        }()

        let anniversaryDTO: AnniversaryDTO? = {
            guard let anniversary = anniversary,
                  let title = anniversary.title,
                  let date = anniversary.Date
            else { return nil }

            let formatted = date.formattedYYYYMMDD()
            return AnniversaryDTO(title: title, date: formatted)
        }()
        
//        let birthDayString = birthDay?.formattedYYYYMMDD()

        return FriendInitDTO(
            name: name,
            source: sourceString,
            contactFrequency: ContactFrequencyDTO(
                contactWeek: contactWeek,
                dayOfWeek: dayOfWeek
            ),
            imageUploadRequest: imageUploadRequest,
            anniversary: anniversaryDTO,
//            birthDay: birthDayString,
            phone: phoneNumber
        )
    }
}

extension ContactSource {
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
        case .biweekly: return "EVERY_2WEEK"
        case .monthly: return "EVERY_MONTH"
        case .semiAnnually: return "EVERY_6MONTH"
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
//    let birthDay: String?
    // TODO: - relationship 포함되어야함
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
    let anniversary: AnniversaryDTO?
}
