import Foundation

struct DailyTaskStats: Identifiable, Codable {
    let id: String // 使用日期字符串作为ID
    let date: String // 日期，格式：yyyy-MM-dd
    let failedTasksCount: Int // 未成功打卡的任务数（未打卡或被拒绝）
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case failedTasksCount = "failed_tasks_count"
    }
}

struct MonthlyTaskStats: Codable {
    let month: String // 月份，格式：yyyy-MM
    let dailyStats: [DailyTaskStats]
    
    enum CodingKeys: String, CodingKey {
        case month
        case dailyStats = "daily_stats"
    }
} 