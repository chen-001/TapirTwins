import Foundation

struct Dream: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var date: String
    var createdAt: String
    var updatedAt: String?
    var spaceId: String?
    var userId: String?
    var username: String?
    var mood: String?
    
    // AI解梦结果
    var dreamInterpretations: [DreamInterpretation]?
    // AI续写结果
    var dreamContinuations: [DreamContinuation]?
    // AI预言结果
    var dreamPredictions: [DreamPrediction]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case date
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case spaceId = "space_id"
        case userId = "user_id"
        case username
        case mood
        case dreamInterpretations = "dream_interpretations"
        case dreamContinuations = "dream_continuations"
        case dreamPredictions = "dream_predictions"
    }
}

// 用于创建新梦境的请求模型
struct DreamRequest: Codable {
    var title: String
    var content: String
    var date: String
    var spaceId: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case content
        case date
        case spaceId = "space_id"
    }
}

// AI解梦结果模型
struct DreamInterpretation: Identifiable, Codable {
    var id: String
    var dreamId: String
    var style: String // "mystic", "scientific", "humorous"
    var content: String
    var createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case dreamId = "dream_id"
        case style
        case content
        case createdAt = "created_at"
    }
}

// AI续写结果模型
struct DreamContinuation: Identifiable, Codable {
    var id: String
    var dreamId: String
    var style: String // "comedy", "tragedy", "mystery", "scifi", "ethical"
    var content: String
    var createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case dreamId = "dream_id"
        case style
        case content
        case createdAt = "created_at"
    }
}

// AI预言结果模型
struct DreamPrediction: Identifiable, Codable {
    var id: String
    var dreamId: String
    var content: String
    var createdAt: String
    var style: String? // 预言时间范围
    
    enum CodingKeys: String, CodingKey {
        case id
        case dreamId = "dream_id"
        case content
        case createdAt = "created_at"
        case style
    }
}

// 新增：梦境报告模型
struct DreamReport: Identifiable, Codable {
    var id: String
    var userId: String
    var reportType: String // "week", "month", "year"
    var content: String    // 报告内容
    var createdAt: String
    var dreamsCount: Int   // 报告包含的梦境数量
    var startDate: String  // 报告的起始日期
    var endDate: String    // 报告的结束日期
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case reportType = "report_type"
        case content
        case createdAt = "created_at"
        case dreamsCount = "dreams_count"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

// 新增：梦境报告请求模型
struct DreamReportRequest: Codable {
    var reportType: String
    var startDate: String
    var endDate: String
    
    enum CodingKeys: String, CodingKey {
        case reportType = "report_type"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

// 人物志模型声明 - 实际实现在DreamViewModel中
// struct CharacterStory: Identifiable, Codable { ... }
