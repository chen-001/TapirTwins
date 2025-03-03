import Foundation

struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
}

struct UserSettings: Codable {
    var defaultShareSpaceId: String?
    var dreamReminderEnabled: Bool = true
    var dreamReminderTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    var interpretationLength: Int = 400 // 默认解梦字数
    var continuationLength: Int = 400 // 默认续写字数
    var predictionLength: Int = 400 // 默认预言字数
    // 梦境分析的时间范围设置
    var dreamAnalysisTimeRange: AnalysisTimeRange = .month
    // 梦境报告的时间范围设置
    var dreamReportTimeRange: ReportTimeRange = .month
    
    static let defaultsKey = "userSettings"
    
    static func load() -> UserSettings {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let settings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            return settings
        }
        return UserSettings()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: UserSettings.defaultsKey)
        }
    }
}

// 梦境分析时间范围枚举
enum AnalysisTimeRange: String, Codable, CaseIterable {
    case week = "week"      // 一周
    case month = "month"    // 一个月
    case quarter = "quarter" // 三个月
    case halfYear = "halfYear" // 半年
    case year = "year"      // 一年
    
    var displayName: String {
        switch self {
        case .week: return "最近一周"
        case .month: return "最近一个月"
        case .quarter: return "最近三个月"
        case .halfYear: return "最近半年"
        case .year: return "最近一年"
        }
    }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .halfYear: return 180
        case .year: return 365
        }
    }
}

// 梦境报告时间范围枚举
enum ReportTimeRange: String, Codable, CaseIterable {
    case week = "week"      // 周报
    case month = "month"    // 月报
    case year = "year"      // 年报
    
    var displayName: String {
        switch self {
        case .week: return "周度报告"
        case .month: return "月度报告"
        case .year: return "年度报告"
        }
    }
}

struct UserSettingsRequest: Codable {
    var defaultShareSpaceId: String?
    var dreamReminderEnabled: Bool?
    var dreamReminderTime: Date?
    var interpretationLength: Int?
    var continuationLength: Int?
    var predictionLength: Int?
    var dreamAnalysisTimeRange: AnalysisTimeRange?
    var dreamReportTimeRange: ReportTimeRange?
}

struct UserSettingsResponse: Codable {
    var defaultShareSpaceId: String?
    var dreamReminderEnabled: Bool?
    var dreamReminderTime: Date?
    var interpretationLength: Int?
    var continuationLength: Int?
    var predictionLength: Int?
    var dreamAnalysisTimeRange: AnalysisTimeRange?
    var dreamReportTimeRange: ReportTimeRange?
}

struct AuthResponse: Codable {
    let user: User
    let token: String
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let password: String
    let email: String
} 