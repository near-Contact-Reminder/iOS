import Foundation

extension Date {
    /// 주기 설정의 다음주기 M/d EEE
    func nextCheckInDate(for frequency: CheckInFrequency) -> String {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        var nextDate: Date?

        switch frequency {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: self)
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: self)
        case .biweekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 2, to: self)
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: self)
        case .semiAnnually:
            nextDate = calendar.date(byAdding: .month, value: 6, to: self)
        default:
            return "-"
        }

        guard let date = nextDate else { return "-" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "M/d EEE"

        return formatter.string(from: date)
    }
    
    /// 주기 설정의 다음주기의 요일 반환 EEEE
    func nextCheckInDateDayOfTheWeek(for frequency: CheckInFrequency) -> String {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        var nextDate: Date?

        switch frequency {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: self)
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: self)
        case .biweekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 2, to: self)
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: self)
        case .semiAnnually:
            nextDate = calendar.date(byAdding: .month, value: 6, to: self)
        default:
            return "-"
        }

        guard let date = nextDate else { return "-" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "EEEE"

        return formatter.string(from: date)
    }

    func nextCheckInDateValue(for frequency: CheckInFrequency) -> Date? {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: self)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: self)
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: self)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: self)
        case .semiAnnually:
            return calendar.date(byAdding: .month, value: 6, to: self)
        default:
            return nil
        }
    }
    
    static func nextSpecialDate(from baseDate: Date?) -> Date? {
        guard let baseDate else { return nil }
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let now = Date()
        
        let month = calendar.component(.month, from: baseDate)
        let day = calendar.component(.day, from: baseDate)
        let currentYear = calendar.component(.year, from: now)

        if let thisYear = calendar.date(from: DateComponents(year: currentYear, month: month, day: day)),
           thisYear >= now {
            return thisYear
        } else {
            return calendar.date(from: DateComponents(year: currentYear + 1, month: month, day: day))
        }
    }

    func weekdayKorean() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    func formattedYYYYMMDD() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    func formattedYYYYMMDDWithDot() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: self)
    }
    
    func formattedYYMMDDWithDot() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: self)
    }
    
    func formattedYYYYMMDDMoreCloser() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 dd일 더 가까워졌어요"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: self)
    }
    
    func startOfDayInKorea() -> Date {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: self
        )
        return calendar.date(from: components) ?? self
    }
}
