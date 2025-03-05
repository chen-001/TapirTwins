import Foundation

// 空响应结构体，用于DELETE等不返回内容的请求
struct EmptyResponse: Codable {}

// 错误响应模型
struct ErrorResponse: Codable {
    let error: String
}

// MARK: - 请求模型 