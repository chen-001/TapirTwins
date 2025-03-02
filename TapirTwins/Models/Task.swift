import Foundation

struct Task: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let dueDate: String?
    let createdAt: String
    let updatedAt: String
    let completedToday: Bool
    let requiredImages: Int
    let spaceId: String?
    let submitterId: String?
    let status: TaskStatus?
    let assignedSubmitterId: String?  // 指定的打卡者ID
    let assignedApproverIds: [String]?  // 指定的审阅者ID列表
    let assignedSubmitterName: String?  // 指定的打卡者名称
    let assignedApproverNames: [String]?  // 指定的审阅者名称列表
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case dueDate = "due_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedToday = "completed_today"
        case requiredImages = "required_images"
        case spaceId = "space_id"
        case submitterId = "submitter_id"
        case status
        case assignedSubmitterId = "assigned_submitter_id"
        case assignedApproverIds = "assigned_approver_ids"
        case assignedSubmitterName = "assigned_submitter_name"
        case assignedApproverNames = "assigned_approver_names"
    }
    
    // 添加一个普通的初始化方法
    init(id: String, title: String, description: String? = nil, dueDate: String? = nil, 
         createdAt: String, updatedAt: String, completedToday: Bool = false, 
         requiredImages: Int = 1, spaceId: String? = nil, submitterId: String? = nil, 
         status: TaskStatus? = .pending, assignedSubmitterId: String? = nil, 
         assignedApproverIds: [String]? = nil, assignedSubmitterName: String? = nil,
         assignedApproverNames: [String]? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedToday = completedToday
        self.requiredImages = requiredImages
        self.spaceId = spaceId
        self.submitterId = submitterId
        self.status = status
        self.assignedSubmitterId = assignedSubmitterId
        self.assignedApproverIds = assignedApproverIds
        self.assignedSubmitterName = assignedSubmitterName
        self.assignedApproverNames = assignedApproverNames
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try container.decode(String.self, forKey: .id)
        } catch {
            print("解析任务ID失败: \(error)")
            throw error
        }
        
        do {
            title = try container.decode(String.self, forKey: .title)
        } catch {
            print("解析任务标题失败: \(error)")
            throw error
        }
        
        do {
            description = try container.decodeIfPresent(String.self, forKey: .description)
        } catch {
            print("解析任务描述失败: \(error)")
            description = nil
        }
        
        do {
            dueDate = try container.decodeIfPresent(String.self, forKey: .dueDate)
        } catch {
            print("解析任务截止日期失败: \(error)")
            dueDate = nil
        }
        
        do {
            createdAt = try container.decode(String.self, forKey: .createdAt)
        } catch {
            print("解析任务创建时间失败: \(error)")
            throw error
        }
        
        do {
            updatedAt = try container.decode(String.self, forKey: .updatedAt)
        } catch {
            print("解析任务更新时间失败: \(error)")
            throw error
        }
        
        // 如果completedToday不存在或为null，设置为false
        do {
            completedToday = try container.decodeIfPresent(Bool.self, forKey: .completedToday) ?? false
        } catch {
            print("解析任务完成状态失败: \(error)")
            completedToday = false
        }
        
        // 确保requiredImages字段存在，否则使用默认值1
        do {
            requiredImages = try container.decodeIfPresent(Int.self, forKey: .requiredImages) ?? 1
        } catch {
            print("解析任务所需图片数量失败: \(error)")
            requiredImages = 1
        }
        
        // 可选字段处理
        do {
            spaceId = try container.decodeIfPresent(String.self, forKey: .spaceId)
        } catch {
            print("解析任务空间ID失败: \(error)")
            spaceId = nil
        }
        
        do {
            submitterId = try container.decodeIfPresent(String.self, forKey: .submitterId)
        } catch {
            print("解析任务提交者ID失败: \(error)")
            submitterId = nil
        }
        
        // 新增字段
        do {
            assignedSubmitterId = try container.decodeIfPresent(String.self, forKey: .assignedSubmitterId)
        } catch {
            print("解析任务指定提交者ID失败: \(error)")
            assignedSubmitterId = nil
        }
        
        do {
            assignedApproverIds = try container.decodeIfPresent([String].self, forKey: .assignedApproverIds)
        } catch {
            print("解析任务指定审批者ID列表失败: \(error)")
            assignedApproverIds = nil
        }
        
        do {
            assignedSubmitterName = try container.decodeIfPresent(String.self, forKey: .assignedSubmitterName)
        } catch {
            print("解析任务指定提交者名称失败: \(error)")
            assignedSubmitterName = nil
        }
        
        do {
            assignedApproverNames = try container.decodeIfPresent([String].self, forKey: .assignedApproverNames)
        } catch {
            print("解析任务指定审批者名称列表失败: \(error)")
            assignedApproverNames = nil
        }
        
        // 如果status字段不存在，则使用默认值pending
        do {
            if let statusString = try container.decodeIfPresent(String.self, forKey: .status),
               let taskStatus = TaskStatus(rawValue: statusString) {
                status = taskStatus
            } else {
                status = .pending
            }
        } catch {
            print("解析任务状态失败: \(error)")
            status = .pending
        }
        
        print("成功解析任务: \(id), 标题: \(title)")
    }
}

enum TaskStatus: String, Codable {
    case pending = "pending"
    case submitted = "submitted"
    case approved = "approved"
    case rejected = "rejected"
}

// 用于创建新任务的请求模型
struct TaskRequest: Codable {
    let title: String
    let description: String?
    let dueDate: String?
    let requiredImages: Int
    var spaceId: String?
    var assignedSubmitterId: String?
    var assignedApproverIds: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case dueDate = "due_date"
        case requiredImages = "required_images"
        case spaceId = "space_id"
        case assignedSubmitterId = "assigned_submitter_id"
        case assignedApproverIds = "assigned_approver_ids"
    }
}

// 任务完成记录模型
struct TaskRecord: Identifiable, Codable {
    let id: String
    let taskId: String
    let date: String
    let createdAt: String
    let images: [String]
    let submitterId: String?
    let status: TaskStatus
    let approverId: String?
    let approvedAt: String?
    let rejectionReason: String?
    let spaceId: String?
    let submitterName: String?
    let approverName: String?
    let assignedApproverIds: [String]?  // 指定的审阅者ID列表
    let assignedApproverNames: [String]?  // 指定的审阅者名称列表
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case date
        case createdAt = "created_at"
        case images
        case submitterId = "submitter_id"
        case status
        case approverId = "approver_id"
        case approvedAt = "approved_at"
        case rejectionReason = "rejection_reason"
        case spaceId = "space_id"
        case submitterName = "submitter_name"
        case approverName = "approver_name"
        case assignedApproverIds = "assigned_approver_ids"
        case assignedApproverNames = "assigned_approver_names"
    }
    
    // 添加自定义解码初始化方法，更灵活地处理可能缺失的字段
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 必需字段
        do {
            id = try container.decode(String.self, forKey: .id)
        } catch {
            print("解码错误: 任务记录ID缺失或无效")
            throw error
        }
        
        do {
            taskId = try container.decode(String.self, forKey: .taskId)
        } catch {
            print("解码错误: 任务记录的任务ID缺失或无效")
            throw error
        }
        
        do {
            date = try container.decode(String.self, forKey: .date)
        } catch {
            print("解码错误: 任务记录日期缺失或无效")
            throw error
        }
        
        do {
            createdAt = try container.decode(String.self, forKey: .createdAt)
        } catch {
            print("解码错误: 任务记录创建时间缺失或无效")
            throw error
        }
        
        // 可选字段
        do {
            images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        } catch {
            print("解码错误: 任务记录图片解析失败，使用空数组")
            images = []
        }
        
        submitterId = try container.decodeIfPresent(String.self, forKey: .submitterId)
        approverId = try container.decodeIfPresent(String.self, forKey: .approverId)
        approvedAt = try container.decodeIfPresent(String.self, forKey: .approvedAt)
        rejectionReason = try container.decodeIfPresent(String.self, forKey: .rejectionReason)
        spaceId = try container.decodeIfPresent(String.self, forKey: .spaceId)
        submitterName = try container.decodeIfPresent(String.self, forKey: .submitterName)
        approverName = try container.decodeIfPresent(String.self, forKey: .approverName)
        
        // 处理可能缺失的审阅者ID和名称
        do {
            assignedApproverIds = try container.decodeIfPresent([String].self, forKey: .assignedApproverIds)
        } catch {
            print("解码错误: 任务记录指定审阅者ID列表解析失败")
            assignedApproverIds = nil
        }
        
        do {
            assignedApproverNames = try container.decodeIfPresent([String].self, forKey: .assignedApproverNames)
        } catch {
            print("解码错误: 任务记录指定审阅者名称列表解析失败")
            assignedApproverNames = nil
        }
        
        // 处理状态字段，如果缺失或无效则使用默认值
        do {
            if let statusString = try container.decodeIfPresent(String.self, forKey: .status),
               let taskStatus = TaskStatus(rawValue: statusString) {
                status = taskStatus
            } else {
                print("任务记录状态字段缺失或无效，使用默认值submitted")
                status = .submitted
            }
        } catch {
            print("解码错误: 任务记录状态解析失败，使用默认值submitted: \(error)")
            status = .submitted
        }
        
        print("成功解析任务记录: \(id), 任务ID: \(taskId)")
    }
}

// 任务完成请求模型
struct TaskCompleteRequest: Codable {
    let images: [String]
}

// 任务完成响应模型
struct TaskCompleteResponse: Codable {
    let success: Bool
    let message: String
    let recordId: String?
    let historyRecord: HistoryRecord?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case recordId = "record_id"
        case historyRecord = "history_record"
    }
}

// 历史记录模型
struct HistoryRecord: Codable {
    let id: String
    let taskId: String
    let date: String
    let createdAt: String
    let userId: String
    let userName: String
    let action: String
    let description: String
    let spaceId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case date
        case createdAt = "created_at"
        case userId = "user_id"
        case userName = "user_name"
        case action
        case description
        case spaceId = "space_id"
    }
}

// 任务审批请求
struct TaskApproveRequest: Codable {
    let comment: String
    
    enum CodingKeys: String, CodingKey {
        case comment
    }
}

// 任务拒绝请求
struct TaskRejectRequest: Codable {
    let reason: String
    
    enum CodingKeys: String, CodingKey {
        case reason
    }
}
