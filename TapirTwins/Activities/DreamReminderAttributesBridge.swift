import Foundation
import ActivityKit
import WidgetKit

// 这是桥接文件，重新导出Widget扩展中定义的类型，确保主应用可以访问相同的类型定义

// 梦境提醒活动的属性
public struct DreamReminderAttributes: ActivityAttributes {
    // 活动属性结构体
    public typealias ContentState = ReminderState
    
    // 添加空的初始化方法
    public init() {}
}

// ContentState定义
public struct ReminderState: Codable, Hashable {
    // 使用基本类型存储时间戳，避免Date的编解码问题
    public var reminderTimeInterval: TimeInterval
    public var message: String
    
    // 计算属性，用于获取Date对象
    public var reminderTime: Date {
        return Date(timeIntervalSince1970: reminderTimeInterval)
    }
    
    // 简单的初始化方法，接受Date参数
    public init(reminderTime: Date, message: String = "记录你的梦境") {
        self.reminderTimeInterval = reminderTime.timeIntervalSince1970
        self.message = message
    }
} 