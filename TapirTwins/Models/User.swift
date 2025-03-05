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
    // 新增：梦境报告长度设置
    var dreamReportLength: ReportLength = .medium
    // 新增：是否只包含自己记录的梦境
    var onlySelfRecordings: Bool = false
    // 任务统计起始日期
    var statisticsStartDate: String?
    
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

// 新增：梦境报告长度枚举
enum ReportLength: String, Codable, CaseIterable {
    case brief = "brief"        // 简洁
    case medium = "medium"      // 中等
    case detailed = "detailed"  // 详细
    
    var displayName: String {
        switch self {
        case .brief: return "简洁"
        case .medium: return "标准"
        case .detailed: return "详细"
        }
    }
    
    var wordCount: Int {
        switch self {
        case .brief: return 500
        case .medium: return 1000
        case .detailed: return 2000
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
    var dreamReportLength: ReportLength?
    var onlySelfRecordings: Bool?
    var statisticsStartDate: String?
    
    // 添加一个简单的初始化方法，只接收统计起始日期
    init(statisticsStartDate: String) {
        self.statisticsStartDate = statisticsStartDate
    }
    
    // 添加只接收梦境报告长度的初始化方法
    init(dreamReportLength: ReportLength) {
        self.dreamReportLength = dreamReportLength
    }
    
    // 添加只接收是否只包含自己记录的梦境设置的初始化方法
    init(onlySelfRecordings: Bool) {
        self.onlySelfRecordings = onlySelfRecordings
    }
    
    // 添加完整的初始化方法，兼容现有代码
    init(defaultShareSpaceId: String? = nil,
         dreamReminderEnabled: Bool? = nil,
         dreamReminderTime: Date? = nil,
         interpretationLength: Int? = nil,
         continuationLength: Int? = nil,
         predictionLength: Int? = nil,
         dreamAnalysisTimeRange: AnalysisTimeRange? = nil,
         dreamReportTimeRange: ReportTimeRange? = nil,
         dreamReportLength: ReportLength? = nil,
         onlySelfRecordings: Bool? = nil,
         statisticsStartDate: String? = nil) {
        self.defaultShareSpaceId = defaultShareSpaceId
        self.dreamReminderEnabled = dreamReminderEnabled
        self.dreamReminderTime = dreamReminderTime
        self.interpretationLength = interpretationLength
        self.continuationLength = continuationLength
        self.predictionLength = predictionLength
        self.dreamAnalysisTimeRange = dreamAnalysisTimeRange
        self.dreamReportTimeRange = dreamReportTimeRange
        self.dreamReportLength = dreamReportLength
        self.onlySelfRecordings = onlySelfRecordings
        self.statisticsStartDate = statisticsStartDate
    }
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
    var dreamReportLength: ReportLength?
    var onlySelfRecordings: Bool?
    var statisticsStartDate: String?
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