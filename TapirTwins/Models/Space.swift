import Foundation

// 空间成员角色
enum MemberRole: String, Codable {
    case submitter = "submitter"  // 打卡者
    case approver = "approver"    // 审批者
    case admin = "admin"          // 管理员（创建者）
}

// 空间成员
struct SpaceMember: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    let username: String
    let role: MemberRole
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case role
    }
}

// 空间模型
struct Space: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let creatorId: String
    let members: [SpaceMember]
    let createdAt: String
    let updatedAt: String
    let inviteCode: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case creatorId = "creator_id"
        case members
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case inviteCode = "invite_code"
    }
}

// 创建空间请求
struct CreateSpaceRequest: Codable {
    let name: String
    let description: String
}

// 邀请成员请求
struct InviteMemberRequest: Codable {
    let username: String
    let role: MemberRole
}

// 加入空间请求
struct JoinSpaceRequest: Codable {
    let inviteCode: String
    
    enum CodingKeys: String, CodingKey {
        case inviteCode = "invite_code"
    }
} 