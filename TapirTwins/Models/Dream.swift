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
